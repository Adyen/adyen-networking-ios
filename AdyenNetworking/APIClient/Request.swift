//
// Copyright (c) 2021 Adyen N.V.
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
/// Represents an API request.
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
    var headers: [String: String] { get }
    
    /// :nodoc:
    /// The query parameters.
    var queryParameters: [URLQueryItem] { get }
    
    /// :nodoc:
    /// The HTTP method.
    var method: HTTPMethod { get }
    
}

/// Represents an API response.
public protocol Response: Decodable { }

/// Represents an API download response.
public struct DownloadResponse: Response {
    
    let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    enum CodingKeys: CodingKey {
        case url
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
    }
}

/// Represents an empty API response.
public struct EmptyResponse: Response {
    
    public init() { }
}

/// Represents an API Error response.
public protocol ErrorResponse: Response, Error { }

public struct EmptyErrorResponse: ErrorResponse { }
