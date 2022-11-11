//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation
import Vapor

public func configure(_ app: Application) throws {
    try routes(app)
}

private func routes(_ app: Application) throws {
    
    // let registry = LocalRegistry(baseDirectory: app.directory.publicDirectory)
    
    let cachePath = (app.directory.publicDirectory as NSString).appendingPathComponent("localCache")
    let configPath = (app.directory.publicDirectory as NSString).appendingPathComponent("localCacheConfig.json")
    let registry = LocalCacheRegistry(configurationPath: configPath, cachePath: cachePath)
    
    let registryService = RegistryService(registry: registry)
    
    app.post { req async in
        "It works!"
    }

    app.get(.constant(registryService.scope), .catchall) { request async in
        await registryService.handle(request)
    }
}
