//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation

protocol SPMRegistry {
    var scope: String { get }
    
    func releases(for packageName: String) async throws -> [String]
    func zipChecksum(for packageName: String, version: String) async throws -> String
    func zipData(for packageName: String, version: String) async throws -> Data
    func manifestData(for packageName: String, version: String) async throws -> Data
}
