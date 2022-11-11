//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation

extension FileManager {
    
    func directoryExists(atPath path: String) -> Bool {
        var isDirectory = ObjCBool(false)
        return fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func shallowSubdirectories(atPath path: String) -> [String] {
        guard directoryExists(atPath: path) else {
            return []
        }
        let contents = (try? contentsOfDirectory(atPath: path)) ?? []
        return contents.compactMap {
            let fullPath = (path as NSString).appendingPathComponent($0)
            guard directoryExists(atPath: fullPath) else {
                return nil
            }
            return $0
        }
    }
}
