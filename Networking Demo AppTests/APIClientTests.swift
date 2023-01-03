//
//  APIClientTests.swift
//  Networking Demo AppTests
//
//  Created by Mohamed Eldoheiri on 8/17/21.
//

import XCTest
import AdyenNetworking
@testable import Networking_Demo_App

class APIClientTests: XCTestCase {
    
    let apiClient = APIClient(apiContext: APIContext())

    func testInvalidGetRequest() throws {
        let apiClientExpectation = expectation(description: "expect apiClient call back to be called.")
        let invalidGetRequest = GetUsersRequest(userId: "xxxxxx")
        apiClient.perform(invalidGetRequest) { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertTrue(error is GetUsersErrorResponse)
                apiClientExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testValidGetRequest() throws {
        let apiClientExpectation = expectation(description: "expect apiClient call back to be called.")
        let validGetRequest = GetUsersRequest()
        apiClient.perform(validGetRequest) { result in
            switch result {
            case .success:
                apiClientExpectation.fulfill()
            case .failure:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testValidCreateRequest() throws {
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
        
        let result: HTTPResponse = try await api.perform(request)
        let responseBody = result.responseBody
        
        do {
            guard let fileData = try? Data(contentsOf: responseBody.url) else {
                XCTFail("unable to read downloaded data file")
                return
            }
            let image = UIImage(data: fileData)
            XCTAssertNotNil(image)
            
            try FileManager.default.removeItem(at: responseBody.url)
        } catch {
            XCTFail(error.localizedDescription)
        }
        await waitForExpectations(timeout: 10, handler: nil)
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
    
    @available(iOS 15.0.0, *)
    func testAsyncSuccessDownloadRequest() async throws {
        let request = TestDownloadRequest()
        let api = APIClient(apiContext: SimpleAPIContext())
        let apiResult = try await api.perform(request)
        
        let downloadRequest = URLRequest(url: URL(string: "https://www.adyen.com/dam/jcr:b07f6545-f41b-4afd-862c-66b7d953d886/presskit-photo-branded.jpg")!)
        let urlSession = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: .main
        )
        
        let downloadResult = try await urlSession.download(for: downloadRequest)
        guard let _ = try? Data(contentsOf: downloadResult.0) else {
            XCTFail("Error accessing downloaded data")
            return
        }
        
        try FileManager.default.removeItem(at: downloadResult.0)
        try FileManager.default.removeItem(at: apiResult.responseBody.url)
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
    func testResponseDataIsCorrect() async throws {
        let name = UUID().uuidString
        let newUser = UserModel(id: Int.random(in: 0...1000),
                                name: name,
                                email: "\(name)@gmail.com",
                                gender: .female,
                                status: .active)
        let validCreateRequest = CreateUsersRequest(userModel: newUser)
        let apiResult: HTTPDataResponse<CreateUsersResponse> = try await apiClient.perform(validCreateRequest)
        
        let responseData: CreateUsersResponse = try Coder().decode(CreateUsersResponse.self, from: apiResult.responseData)
        
        XCTAssertEqual(responseData.data.email, apiResult.responseBody.data.email)
        XCTAssertEqual(responseData.data.gender, apiResult.responseBody.data.gender)
        XCTAssertEqual(responseData.data.id, apiResult.responseBody.data.id)
        XCTAssertEqual(responseData.data.name, apiResult.responseBody.data.name)
        XCTAssertEqual(responseData.data.status, apiResult.responseBody.data.status)
    }
    
    /// Manually call the api using url session, and then call using the api client, and check the responseData from the APIClient response
    /// is the same as the raw response received from the call to urlSession.data
    @available(iOS 15.0.0, *)
    func testResponseDataSuccess() async throws {
        // Arrange
        var request = URLRequest(url: URL(string: "https://gorest.co.in/public/v1/users")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = APIContext().headers
        let urlSession = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: .main
        )
        let getUsersRequest = GetUsersRequest()
        
        // Act
        let apiResult: HTTPDataResponse<GetUsersResponse> = try await apiClient.perform(getUsersRequest)
        let result = try await urlSession.data(for: request) as (data: Data, urlResponse: URLResponse)
        
        // Assert
        let resultData = result.0
        XCTAssertEqual(apiResult.responseData, resultData)
    }
}
