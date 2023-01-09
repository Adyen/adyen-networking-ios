//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// :nodoc:
/// Describes any API Client.
public protocol APIClientProtocol: AnyObject {
    /// Callback to be executed when the API request is complete.
    typealias CompletionHandler<T> = (Result<T, Error>) -> Void
    
    /// Performs the API request.
    /// - Parameter request: The ``Request`` to be performed.
    func perform<R>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>) where R: Request
    
    /// Performs the API request to download.
    /// - Parameter request: The ``Request`` to be performed which has a `ResponseType` of ``DownloadResponse``.
    ///
    /// The ``DownloadResponse`` `ResponseType` of the ``Request`` is returned with the default `URLSession` temporary `URL`.
    ///
    /// The asynchronous ``AsyncAPIClientProtocol`` provides further functionality including providing a destination `URL` with appropriate filename, as well as the ability to receive progress updates.
    func perform<R>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>) where R: Request, R.ResponseType == DownloadResponse
}

/// :nodoc:
/// Describes any async API Client.
@available(iOS 15.0.0, *)
public protocol AsyncAPIClientProtocol: AnyObject {
    /// Performs the API request asynchronously.
    /// - Parameter request: The ``Request`` to be performed.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``HTTPErrorResponse`` in case of an HTTP error.
    /// - Throws: ``ParsingError`` in case of an error during response decoding.
    /// - Throws: ``APIClientError`` in case of invalid HTTP response.
    func perform<R>(_ request: R) async throws -> HTTPResponse<R.ResponseType> where R: Request
    
    /// Performs the API request to download asynchronously.
    /// - Parameter request: The ``Request`` to be performed.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``APIClientError`` in case of invalid HTTP response.
    /// - Throws: ``HTTPErrorResponse`` in case of HTTP error.
    ///
    /// The ``DownloadResponse`` `ResponseType` of the ``HTTPResponse`` contains the destination `URL` to the system's temporary directory containing the downloaded file including an appropriate filename.
    func perform<R>(_ request: R) async throws -> HTTPResponse<R.ResponseType> where R: Request, R.ResponseType == DownloadResponse
    
    /// Performs the API download request asynchronously, providing progress updates to the `onProgressUpdate(Double)` callback on ``AsyncDownloadRequest``.
    /// - Parameter request: The ``AsyncDownloadRequest`` to be performed.
    /// - Returns: ``HTTPResponse`` in case of successful response.
    /// - Throws: ``APIClientError`` in case of invalid HTTP response.
    /// - Throws: ``HTTPErrorResponse`` in case of HTTP error.
    ///
    /// The ``DownloadResponse`` `ResponseType` of the ``HTTPResponse`` contains the destination `URL` to the system's temporary directory containing the downloaded file including an appropriate filename.
    func perform<R>(_ request: R) async throws -> HTTPResponse<R.ResponseType> where R: AsyncDownloadRequest, R.ResponseType == DownloadResponse
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
    
    /// Default file manager
    private let fileManager = FileManager.default
    
    /// :nodoc:
    private let responseValidator: AnyResponseValidator?

    /// Initializes the API client.
    ///
    /// - Parameters:
    ///   - apiContext: The API context.
    ///   - configuration: An optional `URLSessionConfiguration` to be used.
    ///   If no value is provided - `URLSessionConfiguration.ephemereal` will be used.
    ///   - coder: The coder used for encoding request's body and parsing response's body.
    ///   - responseValidator: Optional validator that can be used to validate the raw response received from the API
    ///   - urlSessionDelegate: The delegate used for handling session-level events.
    public init(
        apiContext: AnyAPIContext,
        configuration: URLSessionConfiguration? = nil,
        coder: AnyCoder = Coder(),
        responseValidator: (any AnyResponseValidator)? = nil,
        urlSessionDelegate: URLSessionDelegate? = nil
    ) {
        self.apiContext = apiContext
        self.urlSession = URLSession(
            configuration: configuration ?? Self.buildDefaultConfiguration(),
            delegate: urlSessionDelegate,
            delegateQueue: .main
        )
        self.responseValidator = responseValidator
        self.coder = coder
    }
    
    public func perform<R>(
        _ request: R,
        completionHandler: @escaping CompletionHandler<R.ResponseType>
    ) where R: Request {
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
    
    public func perform<R>(
        _ request: R,
        completionHandler: @escaping CompletionHandler<R.ResponseType>
    ) where R: Request, R.ResponseType == DownloadResponse {
        do {
            urlSession.downloadTask(with: try buildUrlRequest(from: request)) { [weak self] result in
                guard let self = self else { return }
                let result = result
                    .flatMap { response in .init(catching: { try self.handle(response, request) }) }
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
        
        try responseValidator?.validate(result.data, for: request, with: result.headers)
        
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
    ) throws -> HTTPResponse<R.ResponseType> where R.ResponseType == DownloadResponse {
        log(result: result, request: request)
        
        
        try DispatchQueue.global(qos: .default).sync {
            if let data = try? Data(contentsOf: result.url) {
                try responseValidator?.validate(data, for: request, with: result.headers)
            }
        }
        
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
    
    /// Creates an appropriate filename.
    /// - Parameter from: The `URLResponse` from a request used for the suggested filename.
    /// - Parameter with: The `URLRequest` used in place of the response for the filename using the last path component of the request URL.
    /// - Returns: A `String` representing the filename.
    ///
    /// If a filename from the `URLResponse` or `URLRequest` are `nil`, a default filename is given  in the form `Unknown-[UUID].tmp`.
    private func generateFilename(from urlResponse: URLResponse, with urlRequest: URLRequest) -> String {
        urlResponse.suggestedFilename ??
        urlResponse.url?.lastPathComponent ??
        urlRequest.url?.lastPathComponent ??
        "Unknown-\(UUID().uuidString).tmp"
    }
    
    /// Creates a destination URL in the `temporary directory` for a given filename.
    /// - Parameter given: A `String` representing a filename.
    /// - Returns: A destination `URL` file path with the filename.
    private func generateFileDestination(given filename: String) throws -> URL {
        let destinationUrl = fileManager.temporaryDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: destinationUrl.path) {
            try fileManager.removeItem(at: destinationUrl)
        }
        return destinationUrl
    }
}

extension APIClient: AsyncAPIClientProtocol {
    @available(iOS 15.0.0, *)
    public func perform<R>(_ request: R) async throws -> HTTPResponse<R.ResponseType> where R: Request {
        let result = try await urlSession
            .data(for: try buildUrlRequest(from: request)) as (data: Data, urlResponse: URLResponse)
        let httpResult = try URLSessionSuccess(data: result.data, response: result.urlResponse)
        return try handle(httpResult, request)
    }
    
    @available(iOS 15.0.0, *)
    public func perform<R>(
        _ request: R
    ) async throws -> HTTPResponse<R.ResponseType> where R: Request, R.ResponseType == DownloadResponse {
        let urlRequest = try buildUrlRequest(from: request)
        let (locationUrl, urlResponse) = try await urlSession.download(for: urlRequest)
        try handleHttpErrorCodes(from: urlResponse)
        let destinationUrl = try generateFileDestination(
            given: generateFilename(from: urlResponse, with: urlRequest)
        )
        try fileManager.moveItem(at: locationUrl, to: destinationUrl)
        let httpResult = try URLSessionDownloadSuccess(url: destinationUrl, response: urlResponse)
        return try handle(httpResult, request)
    }
    
    @available(iOS 15.0.0, *)
    public func perform<R>(
        _ request: R
    ) async throws -> HTTPResponse<R.ResponseType> where R: AsyncDownloadRequest, R.ResponseType == DownloadResponse {
        let urlRequest = try buildUrlRequest(from: request)
        let (asyncBytes, urlResponse) = try await urlSession.bytes(for: urlRequest)
        try handleHttpErrorCodes(from: urlResponse)
        
        var data = Data()
        let contentLength = urlResponse.expectedContentLength
        if contentLength > 0 {
            data.reserveCapacity(Int(contentLength))
        }
        
        for try await byte in asyncBytes {
            data.append(byte)
            if contentLength > 0 {
                let progress = Double(data.count) / Double(contentLength)
                request.onProgressUpdate?(progress)
            }
        }
        
        let destinationUrl = try generateFileDestination(
            given: generateFilename(from: urlResponse, with: urlRequest)
        )
        fileManager.createFile(atPath: destinationUrl.path, contents: data)
        
        let httpResult = try URLSessionDownloadSuccess(url: destinationUrl, response: urlResponse)
        return try handle(httpResult, request)
    }
    
    private func handleHttpErrorCodes(from urlResponse: URLResponse) throws {
        if let httpResponse = urlResponse as? HTTPURLResponse,
           (400...599).contains(httpResponse.statusCode),
           let headers = httpResponse.allHeaderFields as? [String: String] {
            throw HTTPErrorResponse(
                headers: headers,
                statusCode: httpResponse.statusCode,
                responseBody: EmptyErrorResponse()
            )
        }
    }
}
