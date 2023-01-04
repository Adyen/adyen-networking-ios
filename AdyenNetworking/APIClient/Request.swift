//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// :nodoc:
public enum HTTPMethod: String {
    case post = "POST"
    case get = "GET"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
    
    internal var hasBody: Bool {
        switch self {
        case .post, .put, .patch:
            return true
        case .get, .delete:
            return false
        }
    }
}

/// :nodoc:
/// Describes an API request.
public protocol Request: Encodable {
    /// :nodoc:
    /// The type of the expected response.
    associatedtype ResponseType: Response
    
    /// :nodoc:
    /// The type of the error response.
    associatedtype ErrorResponseType: ErrorResponse
    
    /// :nodoc:
    /// The request path.
    var path: String { get }
    
    /// :nodoc:
    /// How many times the request has been tried.
    var counter: UInt { get set }
    
    /// :nodoc:
    /// The HTTP headers.
    var headers: [String: String] { get set }
    
    /// :nodoc:
    /// The query parameters.
    var queryParameters: [URLQueryItem] { get }
    
    /// :nodoc:
    /// The HTTP method.
    var method: HTTPMethod { get }
}

/// Describes a ``Request`` extension to be used for async downloading.
@available(iOS 15.0.0, *)
public protocol AsyncDownloadRequest: Request {
    var onProgressUpdate: ((_ progress: Double) -> Void)? { get }
}
