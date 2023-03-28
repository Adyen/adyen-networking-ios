//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import AdyenNetworking

internal struct GetUsersErrorResponse: ErrorResponse {
    internal struct Data: Decodable {
        let message: String?
    }
    
    internal let data: Data?
}

internal struct GetUsersRequest: Request {

    typealias ResponseType = GetUsersResponse
    
    typealias ErrorResponseType = GetUsersErrorResponse
    
    let method: HTTPMethod = .get
    
    var path: String { "users/\(userId ?? "")" }
    
    let queryParameters: [URLQueryItem] = []
    
    var userId: String? = nil
    
    var counter: UInt = 0
    
    var headers: [String : String] = [:]
    
    private enum CodingKeys: CodingKey {}
}

internal struct GetUsersResponse: Response {
    let data: [UserModel]
}
