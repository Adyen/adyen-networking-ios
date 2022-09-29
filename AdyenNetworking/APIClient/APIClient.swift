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
    
    /// :nodoc:
    /// Performs the API download request.
    func perform<R: Request>(downloadRequest request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>) where R.ResponseType == DownloadResponse
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
    
    /// Performs the API download request asynchronously.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``APIClientError.invalidResponse`` in case of invalid HTTP response.
    func perform<R: Request>(downloadRequest request: R) async throws -> HTTPResponse<R.ResponseType> where R.ResponseType == DownloadResponse
    
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
public final class APIClient: APIClientProtocol {
    
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
    ///   - coder: The coder used for encoding request's body and parsing response's body.
    ///   - urlSessionDelegate: The delegate used for handling session-level events.
    public init(
        apiContext: AnyAPIContext,
        configuration: URLSessionConfiguration? = nil,
        coder: AnyCoder = Coder(),
        urlSessionDelegate: URLSessionDelegate? = nil
    ) {
        self.apiContext = apiContext
        self.urlSession = URLSession(
            configuration: configuration ?? Self.buildDefaultConfiguration(),
            delegate: urlSessionDelegate,
            delegateQueue: .main
        )
        self.coder = coder
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
    
    /// :nodoc:
    public func perform<R: Request>(
        downloadRequest request: R,
        completionHandler: @escaping CompletionHandler<R.ResponseType>
    ) where R.ResponseType == DownloadResponse {
        do {
            urlSession.downloadTask(with: try buildUrlRequest(from: request)) { [weak self] result in
                guard let self = self else { return }
                let result = result
                    .map { response in self.handle(response, request) }
                    .map(\.responseBody)
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
            if let errorResponse = try? coder.decode(R.ErrorResponseType.self, from: result.data) {
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
    
    private func handle<R: Request>(
        _ result: URLSessionDownloadSuccess,
        _ request: R
    ) -> HTTPResponse<R.ResponseType> where R.ResponseType == DownloadResponse {
        log(result: result, request: request)
        return HTTPResponse(
            headers: result.headers,
            statusCode: result.statusCode,
            responseBody: DownloadResponse(url: result.url)
        )
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
    
    private func log<R: Request>(result: URLSessionDownloadSuccess, request: R) {
        adyenPrint("---- Response Code (/\(request.path)) ----")
        adyenPrint(result.statusCode)
        
        adyenPrint("---- Response Headers (/\(request.path)) ----")
        adyenPrintAsJSON(result.headers)
        
        adyenPrint("---- Response (/\(request.path)) ----")
        adyenPrint(result.url)
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

extension APIClient: AsyncAPIClientProtocol {
    
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
    
    /// Performs the API download request asynchronously.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``APIClientError.invalidResponse`` in case of invalid HTTP response.
    @available(iOS 15.0.0, *)
    public func perform<R: Request>(
        downloadRequest request: R
    ) async throws -> HTTPResponse<R.ResponseType> where R.ResponseType == DownloadResponse {
        let result = try await urlSession
            .download(for: try buildUrlRequest(from: request)) as (url: URL, urlResponse: URLResponse)
        let httpResult = try URLSessionDownloadSuccess(url: result.url, response: result.urlResponse)
        return handle(httpResult, request)
    }
    
}
