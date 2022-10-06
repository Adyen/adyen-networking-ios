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
    func testAsyncDownloadRequest() async throws {
        let request = TestDownloadRequest(delegate: <#T##URLSessionDownloadDelegate?#>)
        let api = APIClient(apiContext: SimpleAPIContext())
        let fileManager = FileManager.default
        
        let result: DownloadResponse = try await api.perform(request).responseBody
        let fileCachePath = fileManager.temporaryDirectory
            .appendingPathComponent("async-test-image.jpg", isDirectory: false)
        
        do {
            try fileManager.copyItem(at: result.url, to: fileCachePath)
            try fileManager.removeItem(at: result.url)
            let image = UIImage(data: try Data(contentsOf: fileCachePath))
            XCTAssertNotNil(image)
            try fileManager.removeItem(at: fileCachePath)
        } catch {
            XCTFail(error.localizedDescription)
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
                let fileCachePath = fileManager.temporaryDirectory
                    .appendingPathComponent("completion-test-image.jpg", isDirectory: false)
                
                do {
                    try fileManager.copyItem(at: downloadResponse.url, to: fileCachePath)
                    try fileManager.removeItem(at: downloadResponse.url)
                    let image = UIImage(data: try Data(contentsOf: fileCachePath))
                    XCTAssertNotNil(image)
                    try fileManager.removeItem(at: fileCachePath)
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
}
