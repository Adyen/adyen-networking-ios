//
// Copyright (c) 2022 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

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
    
    /// Performs the API request asynchronously.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``HTTPErrorResponse`` in case of an HTTP error.
    /// - Throws: ``ParsingError`` in case of an error during response decoding.
    /// - Throws: ``APIClientError.invalidResponse`` in case of invalid HTTP response.
    func perform<R: Request>(_ request: R) async throws -> HTTPResponse<R.ResponseType>
    
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
    
    /// Encoding and Decoding
    private let coder: AnyCoder

    /// Initializes the API client.
    ///
    /// - Parameters:
    ///   - apiContext: The API context.
    ///   - configuration: An optional `URLSessionConfiguration` to be used.
    ///   If no value is provided - `URLSessionConfiguration.ephemereal` will be used.
    ///   - coder: The coder used for encoding request's body and parsing response's body
    public init(
        apiContext: AnyAPIContext,
        configuration: URLSessionConfiguration? = nil,
        coder: AnyCoder = Coder()
    ) {
        self.apiContext = apiContext
        self.urlSession = URLSession(
            configuration: configuration ?? Self.buildDefaultConfiguration(),
            delegate: nil,
            delegateQueue: .main
        )
        self.coder = coder
    }
    
    /// Performs the API request asynchronously.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``HTTPErrorResponse`` in case of an HTTP error.
    /// - Throws: ``ParsingError`` in case of an error during response decoding.
    /// - Throws: ``APIClientError.invalidResponse`` in case of invalid HTTP response.
    @available(iOS 15.0.0, *)
    public func perform<R>(
        _ request: R
    ) async throws -> HTTPResponse<R.ResponseType> where R : Request {
        let result = try await urlSession
            .data(for: try buildUrlRequest(from: request)) as (data: Data, urlResponse: URLResponse)
        let httpResult = try URLSessionSuccess(data: result.data, response: result.urlResponse)
        return try handle(httpResult, request)
    }
    
    /// :nodoc:
    public func perform<R: Request>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>) {
        do {
            urlSession.dataTask(with: try buildUrlRequest(from: request)) { [weak self] result in
                guard let self = self else { return }
                let result = result
                    .flatMap { response in .init(catching: { try self.handle(response, request) }) }
                    .map(\.responseBody)
                    .mapError { (error) -> Error in
                        switch error {
                        case let httpError as HTTPErrorResponse<R.ErrorResponseType>:
                            return httpError.responseBody
                        case let parsingError as ParsingError:
                            return parsingError.underlyingError
                        default:
                            return error
                        }
                    }
                
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
        if request.method.hasBody {
            urlRequest.httpBody = try coder.encode(request)
        }
        
        log(urlRequest: urlRequest, request: request)
        
        return urlRequest
    }
    
    private func handle<R: Request>(
        _ result: URLSessionSuccess,
        _ request: R
    ) throws -> HTTPResponse<R.ResponseType> {
        log(result: result, request: request)
        do {
            if result.data.isEmpty, let emptyResponse = EmptyResponse() as? R.ResponseType {
                return HTTPResponse(
                    headers: result.headers,
                    statusCode: result.statusCode,
                    responseBody: emptyResponse
                )
            } else {
                return HTTPResponse(
                    headers: result.headers,
                    statusCode: result.statusCode,
                    responseBody: try coder.decode(R.ResponseType.self, from: result.data)
                )
            }
        } catch {
            if let errorResponse = try? coder.decode(R.ErrorResponseType.self, from: result.data){
                throw HTTPErrorResponse(
                    headers: result.headers,
                    statusCode: result.statusCode,
                    responseBody: errorResponse
                )
            } else if let decodingError = error as? DecodingError {
                throw ParsingError(
                    headers: result.headers,
                    statusCode: result.statusCode,
                    underlyingError: decodingError
                )
            } else {
                throw error
            }
        }
    }
    
    private func log<R: Request>(urlRequest: URLRequest, request: R) {
        adyenPrint("---- Request (/\(request.path)) ----")
        
        if let body = urlRequest.httpBody {
            adyenPrintAsJSON(body)
        }
        
        adyenPrint("---- Request base url (/\(request.path)) ----")
        adyenPrint(apiContext.environment.baseURL)
        
        if let headers = urlRequest.allHTTPHeaderFields {
            adyenPrint("---- Request Headers (/\(request.path)) ----")
            adyenPrintAsJSON(headers)
        }
        
        if let queryParams = urlRequest.url?.queryParameters {
            adyenPrint("---- Request query (/\(request.path)) ----")
            adyenPrintAsJSON(queryParams)
        }
        
    }
    
    private func log<R: Request>(result: URLSessionSuccess, request: R) {
        adyenPrint("---- Response Code (/\(request.path)) ----")
        adyenPrint(result.statusCode)
        
        adyenPrint("---- Response Headers (/\(request.path)) ----")
        adyenPrintAsJSON(result.headers)
        
        adyenPrint("---- Response (/\(request.path)) ----")
        adyenPrintAsJSON(result.data)
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
