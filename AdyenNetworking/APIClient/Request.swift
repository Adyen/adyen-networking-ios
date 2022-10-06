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
    var headers: [String: String] { get }
    
    /// :nodoc:
    /// The query parameters.
    var queryParameters: [URLQueryItem] { get }
    
    /// :nodoc:
    /// The HTTP method.
    var method: HTTPMethod { get }
}

/// Describes a ``Request`` extension to be used for async downloading.
///
/// A ``DownloadProgressDelegate`` is provided for progress updates.
@available(iOS 15.0.0, *)
public protocol AsyncDownloadRequest: Request {
    var progressDelegate: DownloadProgressDelegate? { get }
}

/// Describes a delegate to be implemented that receives progress updates during a ``AsyncDownloadRequest``.
@available(iOS 15.0.0, *)
public protocol DownloadProgressDelegate {
    /// Delegate method that receives progress updates for a ``AsyncDownloadRequest``
    ///
    /// - Parameter progress: The progress percentage represented as a `Double`.
    func progressUpdate(progress: Double)
}

/// Describes an API response.
public protocol Response: Decodable { }

/// Represents an API download response.
///
/// The `url` property provides the temporary path to the downloaded file.
public struct DownloadResponse: Response {
    public let url: URL
    
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

/// Describes an API Error response.
public protocol ErrorResponse: Response, Error { }

/// Represents an empty API Error response.
public struct EmptyErrorResponse: ErrorResponse { }
