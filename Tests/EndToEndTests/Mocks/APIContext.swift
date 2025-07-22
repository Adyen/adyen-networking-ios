//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
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
        "Authorization": Secrets.goRestAuthBearer
    ]
    
    var queryParameters: [URLQueryItem] = []
}

internal struct SimpleAPIEnvironment: AnyAPIEnvironment {
    let baseURL = URL(string: "https://www.google.com/")!
}

internal struct SimpleAPIContext: AnyAPIContext {
    let environment: AnyAPIEnvironment = SimpleAPIEnvironment()
    
    let headers: [String : String] = [:]
    
    let queryParameters: [URLQueryItem] = []
}
