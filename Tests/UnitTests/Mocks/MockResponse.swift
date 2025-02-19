//
//  MockResponse.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 07/02/2025.
//

@testable import AdyenNetworking

struct MockResponse: Response, Codable, Equatable {
    var someField: String
}

struct MockErrorResponse: ErrorResponse, Codable, Equatable {
    var someErrorField: String
}

extension HTTPURLResponse {

    static func with(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
