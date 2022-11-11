//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation

struct LocalCacheRegistry: SPMRegistry {
    
    let scope = "localCache"
    let configurationPath: String
    let cachePath: String
    
    private var configuration: Configuration {
        get throws {
            try readConfiguration()
        }
    }
    
    func releases(for packageName: String) async throws -> [String] {
        let repoURL = try repo(for: packageName)
        let git = MiniGit(repo: repoURL)
        let tags = try await git.listTags()
        
        // + those cached on disk
        
        return tags.map(\.name)
    }
    
    func zipChecksum(for packageName: String, version: String) async throws -> String {
        let data = try await zipData(for: packageName, version: version)
        return SPMUtilities.computeArchiveChecksum(data)
    }
    
    func zipData(for packageName: String, version: String) async throws -> Data {
        try await demandRelease(for: packageName, version: version)
        
        let path = try zipPath(for: packageName, version: version)
        let zipData = try Data(contentsOf: URL(fileURLWithPath: path))
        return zipData
    }
    
    func manifestData(for packageName: String, version: String) async throws -> Data {
        try await demandRelease(for: packageName, version: version)
        
        let path = try manifestPath(for: packageName, version: version)
        let packageManifestData = try Data(contentsOf: URL(fileURLWithPath: path))
        return packageManifestData
    }
    
    private func demandRelease(for packageName: String, version: String) async throws {
        
        let zipPath = try zipPath(for: packageName, version: version)
        let manifestPath = try manifestPath(for: packageName, version: version)
        let fileManager = FileManager()
        
        if fileManager.fileExists(atPath: zipPath), fileManager.fileExists(atPath: manifestPath) {
            return
        }
        
        let releasePath = try releasePathOnDisk(for: packageName, version: version)
        
        if fileManager.fileExists(atPath: releasePath) {
            try fileManager.removeItem(atPath: releasePath)
        }
        
        let checkoutPath = try rootPathOnDisk(for: packageName) / "Checkout"
        let repoURL = try repo(for: packageName)
        
        let git = MiniGit(repo: repoURL, checkoutPath: checkoutPath)
        try await git.cloneTag(version)
        
        try FileManager().createDirectory(atPath: releasePath, withIntermediateDirectories: true)
        
        try FileManager().copyItem(
            atPath: checkoutPath / "Package.swift",
            toPath: releasePath / "Package.swift"
        )
        
        try await SPMUtilities.archivePackage(at: checkoutPath, into: zipPath)
    }
    
    private func manifestPath(for packageName: String, version: String) throws -> String {
        (try releasePathOnDisk(for: packageName, version: version)) / "Package.swift"
    }
    
    private func zipPath(for packageName: String, version: String) throws -> String {
        (try releasePathOnDisk(for: packageName, version: version)) / "\(packageName).zip"
    }
    
    private func releasePathOnDisk(for packageName: String, version: String) throws -> String {
        try rootPathOnDisk(for: packageName) / "Releases" / version
    }
    
    private func rootPathOnDisk(for packageName: String) throws -> String {
        let path = cachePath / packageName
        try FileManager().createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    private func repo(for packageName: String) throws -> String {
        guard let repoURL = try configuration.packages[packageName] else {
            throw Error.packageNotConfigured
        }
        return repoURL
    }
    
    private func readConfiguration() throws -> Configuration {
        let data = try Data(contentsOf: URL(fileURLWithPath: configurationPath))
        let result = try JSONDecoder().decode(Configuration.self, from: data)
        return result
    }
}

extension LocalCacheRegistry {
    
    enum Error: Swift.Error {
        case packageNotCached
        case packageNotConfigured
        case unknown
    }
    
    struct Configuration: Decodable {
        typealias PackageIdentifier = String
        typealias PackageRepository = String
        
        let packages: [PackageIdentifier: PackageRepository]
    }
}
