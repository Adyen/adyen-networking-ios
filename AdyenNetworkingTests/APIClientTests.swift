//
//  APIClientTests.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 06/02/2025.
//

import XCTest
@testable import AdyenNetworking

class APIClientTests: XCTestCase {
    
    func apiClient(with urlSession: URLSession) -> APIClient {
        APIClient(apiContext: MockAPIContext(), urlSession: urlSession, coder: Coder())
    }
    
    /**
     URLResponse (data?, response(statusCode)?, error?)
     Request (ResponseType, ErrorResponseType)
     */
    
    /// URLSession returns empty response (no data, response or error)
    func test_emptyResponse_fails() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let mockURLSession = MockURLSession(
            nextData: nil,
            nextResponse: nil,
            nextError: nil
        )
        
        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) { result in
            switch result {
            case .success:
                XCTFail("Expecting api call to fail")
            case let .failure(error):
                guard let apiClientError = error as? APIClientError else {
                    XCTFail("Expecting `APIClientError`")
                    return
                }
                XCTAssertEqual(apiClientError, APIClientError.invalidResponse)
                apiClientExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    /// URLSession returns empty response (no data, response or error)
    func test_requestEmptyResponseEmptyErrorResponse_successStatusCodeAndEmptyData_succeeds() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let mockURLSession = MockURLSession(
            nextData: "".data(using: .utf8),
            nextResponse: HTTPURLResponse.with(statusCode: 200),
            nextError: nil
        )
        
        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) {
            self.fullfill(apiClientExpectation, ifSuccess: $0)
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_requestEmptyResponseEmptyErrorResponse_successStatusCode_succeeds() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let mockURLSession = MockURLSession(
            nextData: "{}".data(using: .utf8),
            nextResponse: HTTPURLResponse.with(statusCode: 200),
            nextError: nil
        )
        
        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) {
            self.fullfill(apiClientExpectation, ifSuccess: $0)
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_requestEmptyResponseMockErrorResponse_nonSuccessStatusCodeButValidResponse_fails() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let mockURLSession = MockURLSession(
            nextData: "{}".data(using: .utf8),
            nextResponse: HTTPURLResponse.with(statusCode: 500),
            nextError: nil
        )
        
        // Request
        
        let request = MockRequest<EmptyResponse, MockErrorResponse>()
        apiClient(with: mockURLSession).perform(request) { result in
            switch result {
            case .success:
                // TODO: This should actually fail once fixed
                apiClientExpectation.fulfill()
            case .failure:
                XCTFail("Expecting api call to succeed")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_requestEmptyResponseEmptyErrorResponse_nonSuccessStatusCodeButValidResponse_fails() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let mockURLSession = MockURLSession(
            nextData: "{}".data(using: .utf8),
            nextResponse: HTTPURLResponse.with(statusCode: 500),
            nextError: nil
        )
        
        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) { result in
            switch result {
            case .success:
                // TODO: This should actually fail once fixed
                apiClientExpectation.fulfill()
            case .failure:
                XCTFail("Expecting api call to succeed")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_requestMockResponseEmptyErrorResponse_successStatusCodeAndValidResponse_succeeds() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let response = try JSONEncoder().encode(MockResponse(someField: "Hello"))
        
        let mockURLSession = MockURLSession(
            nextData: response,
            nextResponse: HTTPURLResponse.with(statusCode: 200),
            nextError: nil
        )
        
        let request = MockRequest<MockResponse, MockErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) {
            self.fullfill(apiClientExpectation, ifSuccess: $0)
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_requestMockResponseEmptyErrorResponse_nonSuccessStatusCodeAndValidErrorResponse_fails() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        let mockErrorResponse = MockErrorResponse(someErrorField: "Hello World")
        
        let mockURLSession = MockURLSession(
            nextData: try JSONEncoder().encode(mockErrorResponse),
            nextResponse: HTTPURLResponse.with(statusCode: 404),
            nextError: nil
        )
        
        let request = MockRequest<MockResponse, MockErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) { result in
            switch result {
            case .success:
                XCTFail("Expecting api call to fail")
            case let .failure(error):
                guard let mockError = error as? MockErrorResponse else {
                    XCTFail("Expecting `MockErrorResponse`")
                    return
                }
                XCTAssertEqual(mockError, mockErrorResponse)
                apiClientExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_requestMockResponseEmptyErrorResponse_successStatusCodeButInvalidResponse_fails() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "Expecting apiClient call back to be called.")
        
        let mockURLSession = MockURLSession(
            nextData: "{".data(using: .utf8),
            nextResponse: HTTPURLResponse.with(statusCode: 200),
            nextError: nil
        )
        
        let request = MockRequest<MockResponse, MockErrorResponse>()
        
        // Request
        
        apiClient(with: mockURLSession).perform(request) { result in
            switch result {
            case .success:
                XCTFail("Expecting api call to fail")
            case let .failure(error):
                XCTAssertTrue(error is DecodingError)
                apiClientExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    /*
    func testValidCreateRequest() throws {
        
        // Setup
        
        let apiClientExpectation = expectation(description: "expect apiClient call back to be called.")
        let name = UUID().uuidString
        let newUser = UserModel(id: Int.random(in: 0...1000),
                                name: name,
                                email: "\(name)@gmail.com",
                                gender: .female,
                                status: .active)
        let validCreateRequest = CreateUsersRequest(userModel: newUser)
        apiClient.perform(validCreateRequest) { result in
            switch result {
            case .success:
                apiClientExpectation.fulfill()
            case .failure:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testInvalidCreateRequest() throws {
        let apiClientExpectation = expectation(description: "expect apiClient call back to be called.")
        let invalidCreateRequest = InvalidCreateUsersRequest()
        apiClient.perform(invalidCreateRequest) { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertTrue(error is CreateUsersErrorResponse)
                apiClientExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRetryInvalidCreateRequest() throws {
        let numberOfTries = 2
        let apiClientExpectation = expectation(description: "Expect apiClient callback to be called.")
        let retryExpectation = expectation(description: "Expect scheduler to be called for retry twice.")
        retryExpectation.expectedFulfillmentCount = numberOfTries
        let invalidCreateRequest = InvalidCreateUsersRequest()
        let retryClient = RetryAPIClient(
            apiClient: apiClient,
            scheduler: MockScheduler(maxCount: numberOfTries, onSchedule: {
                retryExpectation.fulfill()
            })
        )
        retryClient.perform(invalidCreateRequest, shouldRetry: { _ in true }) { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertTrue(error is CreateUsersErrorResponse)
                apiClientExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    @available(iOS 15.0.0, *)
    func testAsyncValidCreateRequest() async throws {
        let name = UUID().uuidString
        let newUser = UserModel(id: Int.random(in: 0...1000),
                                name: name,
                                email: "\(name)@gmail.com",
                                gender: .female,
                                status: .active)
        let validCreateRequest = CreateUsersRequest(userModel: newUser)
        _ = try await apiClient.perform(validCreateRequest)
    }
    
    @available(iOS 15.0.0, *)
    func testAsyncInvalidCreateRequest() async throws {
        let invalidCreateRequest = InvalidCreateUsersRequest()
        do {
            _ = try await apiClient.perform(invalidCreateRequest)
            XCTFail("Expected an error to be thrown")
        }  catch { }
    }
    
    @available(iOS 15.0.0, *)
    func testAsyncCallbackDownloadRequest() async throws {
        let downloadProgressExpectation = expectation(description: "Expect download progress to reach 100%.")
        let request = TestAsyncDownloadRequest { progress in
            if progress == 1.0 {
                downloadProgressExpectation.fulfill()
            }
            print("Download progress: \(progress)")
        }
        let api = APIClient(apiContext: SimpleAPIContext())
        
        let result: DownloadResponse = try await api.perform(request).responseBody
        
        do {
            let image = UIImage(data: try Data(contentsOf: result.url))
            XCTAssertNotNil(image)
            try FileManager.default.removeItem(at: result.url)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        await fulfillment(of: [downloadProgressExpectation], timeout: 10)
    }
    
    @available(iOS 15.0.0, *)
    func testAsyncCallbackFailedDownloadRequest() async throws {
        var request = TestAsyncDownloadRequest { progress in
            XCTFail("Callback should not be triggered for failed download.")
        }
        request.path = "kljhfkajsdhfs/////df345.345345m34feg45435"
        let api = APIClient(apiContext: SimpleAPIContext())
        
        do {
            let _ = try await api.perform(request)
            XCTFail("Error was not thrown as it should be.")
        } catch let error {
            guard let errorResponse = error as? HTTPErrorResponse<EmptyErrorResponse> else {
                XCTFail("Unknown error thrown")
                return
            }
            XCTAssertEqual(errorResponse.statusCode, 400)
        }
    }
    
    @available(iOS 15.0.0, *)
    func testAsyncFailedDownloadRequest() async throws {
        var request = TestDownloadRequest()
        request.path = "kljhfkajsdhfs/////df345.345345m34feg45435"
        let api = APIClient(apiContext: SimpleAPIContext())
        
        do {
            let _ = try await api.perform(request)
            XCTFail("Error was not thrown as it should be.")
        } catch let error {
            guard let errorResponse = error as? HTTPErrorResponse<EmptyErrorResponse> else {
                XCTFail("Unknown error thrown")
                return
            }
            XCTAssertEqual(errorResponse.statusCode, 400)
        }
    }
    
    func testCompletionHandlerDownloadRequest() throws {
        let apiClientExpectation = expectation(description: "Expect api client to download image file.")
        let request = TestDownloadRequest()
        let api = APIClient(apiContext: SimpleAPIContext())
        let fileManager = FileManager.default
        
        api.perform(request) { result in
            switch result {
            case .success(let downloadResponse):
                do {
                    let image = UIImage(data: try Data(contentsOf: downloadResponse.url))
                    XCTAssertNotNil(image)
                    try fileManager.removeItem(at: downloadResponse.url)
                    apiClientExpectation.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    @available(iOS 15.0.0, *)
    func testGetRequestValidationForValidationFailed() async throws {
        let responseValidationException = expectation(description: "Expect response validator to be called")
        let mockValidator = MockResponseValidator()
        mockValidator.onValidated = {
            responseValidationException.fulfill()
            throw ValidationError.invalidResponse
        }
        let sut = APIClient(apiContext: APIContext(), responseValidator: mockValidator)
        let validGetRequest = GetUsersRequest()
        do {
            _ = try await sut.perform(validGetRequest)
            XCTFail("Validation exception was not thrown")
        } catch {
            guard let error = error as? ValidationError else {
                XCTFail("Expected ValidationError.invalidResponse to be thrown")
                return
            }
            XCTAssertEqual(error, ValidationError.invalidResponse)
        }
        
        await waitForExpectations(timeout: 10, handler: nil)
    }
    
    @available(iOS 15.0.0, *)
    func testGetRequestValidationForValidationSuccess() async throws {
        let responseValidationException = expectation(description: "Expect response validator to be called")
        let mockValidator = MockResponseValidator()
        mockValidator.onValidated = {
            responseValidationException.fulfill()
            return
        }
        let sut = APIClient(apiContext: APIContext(), responseValidator: mockValidator)
        let validGetRequest = GetUsersRequest()
        do {
            _ = try await sut.perform(validGetRequest)
        } catch {
            XCTFail("Exception thrown while validating response")
        }
        
        await waitForExpectations(timeout: 10, handler: nil)
    }
    
    @available(iOS 15.0.0, *)
    func testFileDownloadValidationForValidationSuccess() async throws {
        let responseValidationException = expectation(description: "Expect response validator to be called")
        let downloadProgressExpectation = expectation(description: "Expect download progress to reach 100%.")
        
        let request = TestAsyncDownloadRequest { progress in
            if progress == 1.0 {
                downloadProgressExpectation.fulfill()
            }
            print("Download progress: \(progress)")
        }
        let mockValidator = MockResponseValidator()
        mockValidator.onValidated = {
            responseValidationException.fulfill()
            return
        }
        let api = APIClient(apiContext: SimpleAPIContext(), responseValidator: mockValidator)
        
        let result: DownloadResponse = try await api.perform(request).responseBody
        do {
            let image = UIImage(data: try Data(contentsOf: result.url))
            XCTAssertNotNil(image)
            try FileManager.default.removeItem(at: result.url)
        } catch {
            XCTFail(error.localizedDescription)
        }
        await waitForExpectations(timeout: 10, handler: nil)
    }
    
    @available(iOS 15.0.0, *)
    func testFileDownloadValidationForValidationFailed() async throws {
        let responseValidationException = expectation(description: "Expect response validator to be called")
        let downloadProgressExpectation = expectation(description: "Expect download progress to reach 100%.")
        
        let request = TestAsyncDownloadRequest { progress in
            XCTAssertFalse(Thread.isMainThread, "Shouldn't be on main thread")
            if progress == 1.0 {
                downloadProgressExpectation.fulfill()
            }
            print("Download progress: \(progress)")
        }
        let mockValidator = MockResponseValidator()
        mockValidator.onValidated = {
            XCTAssertFalse(Thread.isMainThread, "Shouldn't be on main thread")
            responseValidationException.fulfill()
            throw ValidationError.invalidResponse
        }
        let api = APIClient(apiContext: SimpleAPIContext(), responseValidator: mockValidator)
        
        do {
            _ = try await api.perform(request).responseBody
            XCTFail("Expected validation exception to be thrown")
        } catch {
            FileManager.default.clearTmpDirectory()
        }
        await waitForExpectations(timeout: 10, handler: nil)
    }
     */
}

// MARK: - Helpers

extension APIClientTests {
    
    func fullfill<T>(_ expectation: XCTestExpectation, ifSuccess result: Result<T, Error>) {
        switch result {
        case .success:
            expectation.fulfill()
        case .failure:
            XCTFail("Expecting api call to succeed")
        }
    }
}
