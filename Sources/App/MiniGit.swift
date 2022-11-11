//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation

struct MiniGit {
    let repo: String
    let checkoutPath: String
    
    init(repo: String, checkoutPath: String? = nil) {
        self.repo = repo
        self.checkoutPath = checkoutPath ?? FileManager().temporaryDirectory.absoluteString
    }
    
    func listTags() async throws -> [Tag] {
        
        let refPrefix = "refs/tags/"
        
        let output: String
        do {
            output = try Self.run("git ls-remote --refs \(repo) \(refPrefix)\\*")
        } catch {
            print(error.localizedDescription)
            throw error
        }
        
        let rawTags = output
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
        
        return try rawTags.map {
            let components = $0.components(separatedBy: .whitespaces)
            guard components.count == 2 else {
                throw Error.unrecognizedGitOutput
            }
            
            let hash = components[0]
            let ref = components[1]
            
            guard hash.count > 0, ref.hasPrefix(refPrefix) else {
                throw Error.unrecognizedGitOutput
            }
            
            let tagName = ref.replacingOccurrences(of: refPrefix, with: "")
            return Tag(hash: hash, name: tagName)
        }
    }
    
    func cloneTag(_ tag: String) async throws {
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: checkoutPath) {
            try fileManager.removeItem(atPath: checkoutPath)
        }
        try Self.run("git clone --depth 1 --branch \"\(tag)\" \"\(repo)\" \"\(checkoutPath)\"")
    }
    
    /*
     // Does not work well for our purposes
    func zipRepo(into destination: String, tree: String = "HEAD") async throws {
        try Self.run("git archive --format=zip --output \"\(destination)\" \(tree)", workingDirectory: checkoutPath)
    }
    */
    
    @discardableResult
    static func run(_ command: String, workingDirectory: String? = nil) throws -> String {
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

extension MiniGit {
    
    struct Tag {
        let hash: String
        let name: String
    }
    
    enum Error: Swift.Error {
        case unrecognizedGitOutput
        case nonZeroTermination
    }
}
