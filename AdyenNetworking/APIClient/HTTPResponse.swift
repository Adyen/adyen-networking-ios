//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

public struct HTTPResponse<R: Response> {
    
    /// HTTP Headers.
    public let headers: [String: String]
    
    /// HTTP Status Code.
    public let statusCode: Int
    
    /// Response body
    public let responseBody: R
    
}

typealias HTTPErrorResponse<E: ErrorResponse> = HTTPResponse<E>

extension HTTPResponse: Error where R: Error { }
