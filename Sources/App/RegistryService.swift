//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation
import Vapor

struct RegistryService {
    
    let registry: LocalRegistry
    
    var scope: String {
        registry.scope
    }
    
    func handle(_ request: Vapor.Request) async -> Response {
        let components = request.parameters.getCatchall()
        print(components)
        
        guard let packageName = components.first else {
            return Response(status: .badRequest)
        }
        
        if components.count == 1 {
            return await listReleases(for: packageName)
        }
        
        let packageVersion = components[1].replacingOccurrences(of: ".zip", with: "")
        
        if components.count == 2 {
            if components[1].hasSuffix(".zip") {
                return await packageZip(for: packageName, version: packageVersion)
            } else {
                return await releaseDetails(for: packageName, version: packageVersion)
            }
            
        } else if components.count == 3, components[2] == "Package.swift" {
            return await packageManifest(for: packageName, version: packageVersion)
        }
        
        return Response(status: .badRequest)
    }
}

extension RegistryService {
    
    func listReleases(for packageName: String) async -> Response {
    
        struct ReleasesResponse: Encodable {
            let releases: [String: [String: String]]
            
            init(releases: [String]) {
                var releasesDict: [String: [String: String]] = [:]
                for release in releases {
                    releasesDict[release] = [:]
                }
                self.releases = releasesDict
            }
        }
        
        guard let releases = try? await registry.releases(for: packageName) else {
            return .init(status: .notFound)
        }
        
        let response = ReleasesResponse(releases: releases)
        return await Json(value: response)
            .encodeResponse(onError: .internalServerError)
    }
}

extension RegistryService {
    
    struct ReleaseDetailsResponse: Encodable {
        
        struct Resource: Encodable {
            let name: String
            let type: String
            let checksum: String
        }
        
        let id: String
        let version: String
        let resources: [Resource]
        
        static func zippedRelease(forScope scope: String, packageName: String, version: String, checksum: String) -> Self {
            Self(
                id: "\(scope).\(packageName)",
                version: version,
                resources: [
                    Resource(name: "source-archive", type: "application/zip", checksum: checksum)
                ]
            )
        }
    }
    
    func releaseDetails(for packageName: String, version: String) async -> Response {
        guard let checksum = try? await registry.zipChecksum(for: packageName, version: version) else {
            return .init(status: .notFound)
        }
        
        let response = ReleaseDetailsResponse.zippedRelease(
            forScope: scope,
            packageName: packageName,
            version: version,
            checksum: checksum
        )
        return await Json(value: response)
            .encodeResponse(onError: .internalServerError)
    }
}

extension RegistryService {
    
    func packageZip(for packageName: String, version: String) async -> Response {
        await fileReadResponse(of: "application/zip") {
            try await registry.zipData(for: packageName, version: version)
        }
    }
    
    func packageManifest(for packageName: String, version: String) async -> Response {
        await fileReadResponse(of: "text/x-swift") {
            try await registry.manifestData(for: packageName, version: version)
        }
    }
    
    private func fileReadResponse(of type: String, with block: () async throws -> (Data)) async -> Response {
        do {
            let data = try await block()
            return Response(
                status: .ok,
                headers: [
                    "Content-Version": "1",
                    "Content-Type": type
                ],
                body: .init(data: data)
            )
        } catch {
            return Response(status: .notFound)
        }
    }
}

private extension RegistryService {
    
    struct Json<T: Encodable>: SimpleAsyncResponseEncodable {
        let value: T
        
        public func encodeResponse() async throws -> Response {
            let data = try JSONEncoder().encode(value)
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "application/json")
            headers.add(name: .contentVersion, value: "1")
            return .init(status: .ok, headers: headers, body: .init(data: data))
        }
    }
}
