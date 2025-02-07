//
//  TestHelpers.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 06/02/2025.
//

@testable import AdyenNetworking

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
