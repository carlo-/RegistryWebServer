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
    
    let registry = LocalRegistry(baseDirectory: app.directory.publicDirectory)
    let registryService = RegistryService(registry: registry)
    
    app.post { req async in
        "It works!"
    }

    app.get(.constant(registryService.scope), .catchall) { request async in
        await registryService.handle(request)
    }
}
