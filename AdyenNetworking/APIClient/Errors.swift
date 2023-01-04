//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Describes possible `APIClient` errors
public enum APIClientError: LocalizedError {
    
    case invalidResponse
    
    var errorDescription: String {
        return "Invalid Response"
    }
    
}

/// Represents a parsing error object
public struct ParsingError: LocalizedError, AnyDataResponse {
    
    public typealias R = EmptyResponse
    
    /// HTTP Headers.
    public let headers: [String: String]
    
    /// HTTP Status Code.
    public let statusCode: Int
    
    /// Underlying error of type ``DecodingError``
    public let underlyingError: DecodingError
    
    /// Empty response body
    public var responseBody: EmptyResponse
    
    /// The response data which was failed to be parsed
    var responseData: Data
}
