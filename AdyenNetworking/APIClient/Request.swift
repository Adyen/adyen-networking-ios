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
    var headers: [String: String] { get set }
    
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
    var onProgressUpdate: ((_ progress: Double) -> Void)? { get }
}

public struct OpaqueRequest: Request, Decodable {
    
    public typealias ResponseType = EmptyResponse
    public typealias ErrorResponseType = EmptyErrorResponse
    
    public var headers: [String: String] = [:]

    public var path: String = ""
    
    public var counter: UInt = 0
    
    public var body: Data?
    
    public var queryParameters: [URLQueryItem] = []
    
    public var method: HTTPMethod = .post
    
    public var expirationDate: Date = Date()
    
    private enum CodingKeys: CodingKey {}
    
    public func encode(to encoder: Encoder) throws {}
    
    public var isExpired: Bool {
        Date() > expirationDate
    }
    
    public init(
        headers: [String : String],
        path: String,
        counter: UInt,
        body: Data?,
        expirationDate: Date,
        queryParameters: [URLQueryItem],
        method: HTTPMethod
    ) {
        self.headers = headers
        self.path = path
        self.counter = counter
        self.body = body
        self.queryParameters = queryParameters
        self.method = method
    }
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
