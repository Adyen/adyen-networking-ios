//
//  MockRequest.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 07/02/2025.
//

@testable import AdyenNetworking

// MARK: - MockRequest

struct MockRequest<ResponseType: Response, ErrorResponseType: ErrorResponse>: Request {

    var counter: UInt
    var path: String
    var method: HTTPMethod
    var queryParameters: [URLQueryItem]
    var headers: [String: String]

    init(
        counter: UInt = 0,
        path: String = "",
        method: HTTPMethod = .get,
        queryParameters: [URLQueryItem] = [],
        headers: [String : String] = [:]
    ) {
        self.counter = counter
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.headers = headers
    }
}

// MARK: - Encodable Conformance

extension URLQueryItem: @retroactive Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }
}

extension HTTPMethod: @retroactive Encodable {}
