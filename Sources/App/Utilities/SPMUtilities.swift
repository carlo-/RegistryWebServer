//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation
import Crypto

struct SPMUtilities {
    
    static func archivePackage(at packagePath: String, into destination: String) async throws {
        try run("swift package archive-source --output \"\(destination)\"", workingDirectory: packagePath)
    }
    
    static func computeArchiveChecksum(_ archiveData: Data) -> String {
        SHA256.hash(data: archiveData).hex
    }
    
    @discardableResult
    private static func run(_ command: String, workingDirectory: String? = nil) throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil
        
        if let workingDirectory {
            task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        print(output)
        
        guard task.terminationStatus == 0 else {
            throw Error.nonZeroTermination
        }
        
        return output
    }
}

extension SPMUtilities {
    
    enum Error: Swift.Error {
        case nonZeroTermination
    }
}
