//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//
import Foundation

/// Protocol representing a HTTP response which contains raw response
protocol AnyDataResponse: AnyHTTPResponse {
    
    /// Response data representing the raw response info in `Data`
    var responseData: Data { get }
}

/// Struct conforming to `AnyDataResponse` which contains standard HTTP response info, including headers,
/// status code and response body, as well as the raw `Data` response
public struct HTTPDataResponse<R: Response>: AnyDataResponse {
    
    /// HTTP Headers.
    public let headers: [String: String]
    
    /// HTTP Status Code.
    public let statusCode: Int
    
    /// Response body
    public let responseBody: R
    
    /// Raw data response
    public let responseData: Data
}

public typealias HTTPErrorResponse<E: ErrorResponse> = HTTPDataResponse<E>

extension HTTPDataResponse: Error where R: Error { }
