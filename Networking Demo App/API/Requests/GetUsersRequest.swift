//
//  GetUsersRequest.swift
//  Networking Demo App
//
//  Created by Mohamed Eldoheiri on 7/30/21.
//

import Foundation
import AdyenNetworking

internal struct GetUsersRequest: Request {

    typealias ResponseType = GetUsersResponse
    
    let method: HTTPMethod = .get
    
    var path: String { "users/\(userId ?? "")" }
    
    let queryParameters: [URLQueryItem] = []
    
    var userId: String? = nil
    
    var counter: UInt = 0
    
    let headers: [String : String] = [:]
    
    private enum CodingKeys: CodingKey {}
}

internal struct GetUsersResponse: Response {
    typealias ErrorType = HttpError
    
    let data: [UserModel]
}
