//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

/// :nodoc:
/// Describes possible `APIClient` errors
public enum APIClientError: LocalizedError {
    
    case invalidResponse
    
    var errorDescription: String {
        return "Invalid Response"
    }
    
}

/// :nodoc:
/// Describes any API Client.
public protocol APIClientProtocol: AnyObject {
    
    /// :nodoc:
    typealias CompletionHandler<T> = (Result<T, Error>) -> Void
    
    /// :nodoc:
    /// Performs the API request.
    func perform<R: Request>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>)
    
}

/// :nodoc:
/// Describes any async API Client.
@available(iOS 15.0.0, *)
public protocol AsyncAPIClientProtocol: AnyObject {
    
    /// :nodoc:
    /// Performs the API request asynchronously.
    func perform<R: Request>(_ request: R) async throws -> R.ResponseType
    
}

/// :nodoc:
extension APIClientProtocol {

    /// :nodoc:
    public func retryAPIClient(with scheduler: Scheduler) -> AnyRetryAPIClient {
        RetryAPIClient(apiClient: self, scheduler: scheduler)
    }
}

/// :nodoc:
/// The Basic API Client.
public final class APIClient: APIClientProtocol, AsyncAPIClientProtocol {
    
    /// :nodoc:
    public typealias CompletionHandler<T> = (Result<T, Error>) -> Void
    
    /// :nodoc:
    /// The API context.
    public let apiContext: AnyAPIContext
    
    /// :nodoc:
    private let urlSession: URLSession
    
    /// :nodoc:
    /// Initializes the API client.
    ///
    /// - Parameters:
    ///   - apiContext: The API context.
    ///   - configuration: An optional `URLSessionConfiguration` to be used.
    ///   If no value is provided - `URLSessionConfiguration.ephemereal` will be used.
    public init(apiContext: AnyAPIContext, configuration: URLSessionConfiguration? = nil) {
        self.apiContext = apiContext
        self.urlSession = URLSession(
            configuration: configuration ?? Self.buildDefaultConfiguration(),
            delegate: nil,
            delegateQueue: .main
        )
    }
    
    /// :nodoc:
    @available(iOS 15.0.0, *)
    public func perform<R: Request>(_ request: R) async throws -> R.ResponseType {
        let result = try await urlSession
                .data(for: try buildUrlRequest(from: request)) as (data: Data, response: URLResponse)
        
        return try Self.handle(.init(data: result.data, response: result.response), request)
    }
    
    /// :nodoc:
    public func perform<R: Request>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>) {
        do {
            urlSession.dataTask(with: try buildUrlRequest(from: request)) { result in
                let result = result.flatMap { response in .init(catching: { try Self.handle(response, request) }) }
                completionHandler(result)
            }.resume()
        } catch {
            completionHandler(.failure(error))
        }
    }
    
    private func buildUrlRequest<R: Request>(from request: R) throws -> URLRequest {
        let url = apiContext.environment.baseURL.appendingPathComponent(request.path)
        
        var urlRequest = URLRequest(url: add(queryParameters: request.queryParameters + apiContext.queryParameters, to: url))
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers.merging(apiContext.headers, uniquingKeysWith: { key1, _ in key1 })
        if request.method == .post {
            urlRequest.httpBody = try Coder.encode(request)
        }
        
        log(urlRequest: urlRequest, request: request)
        
        return urlRequest
    }
    
    private static func handle<R: Request>(
        _ result: URLSessionSuccess,
        _ request: R
    ) throws -> R.ResponseType {
        do {
            log(result: result, request: request)
            return try Coder.decode(result.data) as R.ResponseType
        } catch {
            if let errorResponse: R.ErrorResponseType = try? Coder.decode(result.data) {
                throw errorResponse
            } else if (200...299).contains(result.response.statusCode) == false {
                throw HttpError(
                    errorCode: result.response.statusCode,
                    errorMessage: "Http \(result.response.statusCode) error"
                )
            } else {
                throw error
            }
        }
    }
    
    private func log<R: Request>(urlRequest: URLRequest, request: R) {
        adyenPrint("---- Request (/\(request.path)) ----")
        
        if let body = urlRequest.httpBody {
            printAsJSON(body)
        }
        
        adyenPrint("---- Request base url (/\(request.path)) ----")
        adyenPrint(apiContext.environment.baseURL)
        
        if let headers = urlRequest.allHTTPHeaderFields {
            adyenPrint("---- Request Headers (/\(request.path)) ----")
            adyenPrint(headers)
        }
        
        if let queryParams = urlRequest.url?.queryParameters {
            adyenPrint("---- Request query (/\(request.path)) ----")
            adyenPrint(queryParams)
        }
        
    }
    
    private static func log<R: Request>(result: URLSessionSuccess, request: R) {
        if let headers = result.response.allHeaderFields as? [String: String] {
            adyenPrint("---- Response Headers (/\(request.path)) ----")
            adyenPrint(headers)
        }
        
        adyenPrint("---- Response (/\(request.path)) ----")
        printAsJSON(result.data)
    }
    
    /// :nodoc:
    private func add(queryParameters: [URLQueryItem], to url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryParameters.isEmpty {
            components?.queryItems = queryParameters
        }
        return components?.url ?? url
    }
    
    /// :nodoc:
    private static func buildDefaultConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        
        if #available(iOS 13.0, *) {
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
        } else {
            config.tlsMinimumSupportedProtocol = .tlsProtocol12
        }
        
        return config
    }
    
}

private func printAsJSON(_ data: Data) {
    guard Logging.isEnabled else { return }
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        adyenPrint(jsonString)
    } catch {
        if let string = String(data: data, encoding: .utf8) {
            adyenPrint(string)
        }
    }
}
