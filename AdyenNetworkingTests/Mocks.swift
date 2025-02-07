//
//  TestHelpers.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 06/02/2025.
//

import XCTest
@testable import AdyenNetworking


// MARK: - MockRequest

struct MockRequest<RT: Response, ET: ErrorResponse>: Request {
    
    typealias ErrorResponseType = ET
    
    var counter: UInt = 0
    
    var path: String
    var method: HTTPMethod
    var queryParameters: [URLQueryItem]
    var headers: [String: String]
    typealias ResponseType = RT
    
    init(
        counter: UInt = 0,
        path: String = "",
        method: HTTPMethod = .get,
        queryParameters: [URLQueryItem] = [],
        headers: [String : String] = [:]
    ) {
        self.counter = counter
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.headers = headers
    }
}

extension URLQueryItem: @retroactive Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }
}

extension HTTPMethod: @retroactive Encodable {}

// MARK: - MockResponse / MockErrorResponse

struct MockResponse: Response, Codable, Equatable {
    var someField: String
}

struct MockErrorResponse: ErrorResponse, Codable, Equatable {
    var someErrorField: String
}

// MARK: - URLResponse

extension HTTPURLResponse {
    
    static func with(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

// MARK: - MockURLSession

class MockURLSession: URLSession, @unchecked Sendable  {
    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?
    
    init(nextData: Data? = nil, nextResponse: URLResponse? = nil, nextError: Error? = nil) {
        self.nextData = nextData
        self.nextResponse = nextResponse
        self.nextError = nextError
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let data = nextData
        let response = nextResponse
        let error = nextError
        return MockURLSessionDataTask {
            completionHandler(data, response, error)
        }
    }
    
    override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        let url = nextData != nil ? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mockfile") : nil
        if let data = nextData {
            try? data.write(to: url!)
        }
        let response = nextResponse
        let error = nextError
        return MockURLSessionDownloadTask {
            completionHandler(url, response, error)
        }
    }
}

// MARK: - MockURLSessionDataTask

class MockURLSessionDataTask: URLSessionDataTask, @unchecked Sendable  {
    private let completionHandler: () -> Void
    
    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
    
    override func resume() {
        completionHandler()
    }
}

// MARK: - MockURLSessionDownloadTask

class MockURLSessionDownloadTask: URLSessionDownloadTask, @unchecked Sendable  {
    private let completionHandler: () -> Void
    
    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
    
    override func resume() {
        completionHandler()
    }
}

// MARK: - MockResponseValidator

public class MockResponseValidator: AnyResponseValidator {
    
    var onValidated: (() throws -> Void)?
    
    public func validate<R>(_ responseData: Data, for request: R, with responseHeaders: [String : String]) throws {
        try onValidated?()
    }
}

// MARK: - FileManager

extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch {}
    }
}

// MARK: - MockAPIContext

internal struct MockAPIContext: AnyAPIContext {
    
    struct MockAPIEnvironment: AnyAPIEnvironment {
        let baseURL = URL(string: "https://www.adyen.com/")!
    }
    
    let environment: AnyAPIEnvironment = MockAPIEnvironment()
    
    let headers: [String : String] = [:]
    
    let queryParameters: [URLQueryItem] = []
}
