//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation

struct LocalRegistry: SPMRegistry {
    
    let scope = "localRegistry"
    let baseDirectory: String
    
    func releases(for packageName: String) async throws -> [String] {
        let path = try pathOnDisk(for: packageName)
        return FileManager().shallowSubdirectories(atPath: path)
    }
    
    func zipChecksum(for packageName: String, version: String) async throws -> String {
        let data = try await zipData(for: packageName, version: version)
        return SPMUtilities.computeArchiveChecksum(data)
    }
    
    func zipData(for packageName: String, version: String) async throws -> Data {
        let packageZipPath = try zipPath(for: packageName, version: version)
        let packageZipData = try Data(contentsOf: URL(fileURLWithPath: packageZipPath))
        return packageZipData
    }
    
    func manifestData(for packageName: String, version: String) async throws -> Data {
        let packageManifestPath = (try pathOnDisk(for: packageName, version: version)) + "/Package.swift"
        let packageManifestData = try Data(contentsOf: URL(fileURLWithPath: packageManifestPath))
        return packageManifestData
    }
    
    private func zipPath(for packageName: String, version: String) throws -> String {
        (try pathOnDisk(for: packageName, version: version)) + "/\(packageName).zip"
    }
    
    private func pathOnDisk(for packageName: String, version: String? = nil) throws -> String {
        let path = baseDirectory + "Example Packages/\(packageName)" + (version.flatMap { "/\($0)" } ?? "")
        guard FileManager().directoryExists(atPath: path) else {
            throw Error.packageNotFound
        }
        return path
    }
}

extension LocalRegistry {
    
    enum Error: Swift.Error {
        case packageNotFound
        case couldNotComputeChecksum
    }
}
