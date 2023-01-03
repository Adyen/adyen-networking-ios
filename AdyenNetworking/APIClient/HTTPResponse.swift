//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Protocol representing a HTTP response, containing headers, status code and body
protocol AnyHTTPResponse {
    
    associatedtype R
    
    /// HTTP Headers.
    var headers: [String: String] { get }
    
    /// HTTP Status Code.
    var statusCode: Int { get }
    
    /// Response body
    var responseBody: R { get }
}

/// Struct conforming to `AnyHTTPResponse` which contains standard HTTP response info, ie headers, status code and response body
public struct HTTPResponse<R: Response>: AnyHTTPResponse {
    
    /// HTTP Headers.
    public let headers: [String: String]
    
    /// HTTP Status Code.
    public let statusCode: Int
    
    /// Response body
    public let responseBody: R
}

public typealias HTTPErrorResponse<E: ErrorResponse> = HTTPResponse<E>

extension HTTPResponse: Error where R: Error { }
