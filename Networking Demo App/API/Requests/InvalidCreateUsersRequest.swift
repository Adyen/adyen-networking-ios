//
//  InvalidCreateUsersRequest.swift
//  Networking Demo App
//
//  Created by Mohamed Eldoheiri on 8/13/21.
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
    
    let headers: [String : String] = [:]
    
    private enum CodingKeys: CodingKey {}
}
