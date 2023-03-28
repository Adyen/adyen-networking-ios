//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import AdyenNetworking

internal struct InvalidCreateUsersRequest: Request {

    typealias ResponseType = CreateUsersResponse
    
    typealias ErrorResponseType = CreateUsersErrorResponse
    
    let method: HTTPMethod = .post
    
    let path: String = "users"
    
    let queryParameters: [URLQueryItem] = []
    
    var counter: UInt = 0
    
    var headers: [String : String] = [:]
    
    private enum CodingKeys: CodingKey {}
}
