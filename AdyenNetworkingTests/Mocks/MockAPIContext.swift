//
//  MockAPIContext.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 07/02/2025.
//

@testable import AdyenNetworking

internal struct MockAPIContext: AnyAPIContext {

    struct MockAPIEnvironment: AnyAPIEnvironment {
        let baseURL = URL(string: "https://www.adyen.com/")!
    }

    let environment: AnyAPIEnvironment = MockAPIEnvironment()

    let headers: [String : String] = [:]

    let queryParameters: [URLQueryItem] = []
}
