//
//  APIContext.swift
//  Networking Demo App
//
//  Created by Mohamed Eldoheiri on 7/30/21.
//

import Foundation
import AdyenNetworking

/// We're using this API as an example:
/// https://gorest.co.in

internal struct Environment: AnyAPIEnvironment {
    var baseURL: URL = URL(string: "https://gorest.co.in/public/v1/")!
    
    static let `default`: Environment = Environment()
}

internal struct APIContext: AnyAPIContext {
    let environment: AnyAPIEnvironment = Environment.default
    
    var headers: [String : String] = [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer e475ecaf522c28108af6b7a99e0ad788c73e9f8b15608ee3a1acef57da1c36f6"
    ]
    
    var queryParameters: [URLQueryItem] = []
}
