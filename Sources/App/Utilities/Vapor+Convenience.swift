//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation
import Vapor

protocol SimpleAsyncResponseEncodable: AsyncResponseEncodable {
    func encodeResponse() async throws -> Vapor.Response
}

extension SimpleAsyncResponseEncodable {
    
    public func encodeResponse(for request: Request) async throws -> Response {
        try await self.encodeResponse()
    }
    
    func encodeResponse(onError errorStatus: HTTPResponseStatus) async -> Response {
        do {
            return try await encodeResponse()
        } catch {
            return Response(status: errorStatus)
        }
    }
}
