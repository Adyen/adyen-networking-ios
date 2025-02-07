//
//  APIClientTests.swift
//  AdyenNetworkingTests
//
//  Created by Alexander Guretzki on 07/02/2025.
//

import Testing
import Foundation
@testable import AdyenNetworking

@MainActor
struct APIClientTests {
    
    struct TestResponse {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?

        init(
            data: Data? = nil,
            statusCode: Int? = nil,
            error: Error? = nil
        ) {
            self.data = data
            self.response = statusCode.map { .with(statusCode: $0) }
            self.error = error
        }
    }
    
    @Test func emptyResponse() async throws {

        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        let response = TestResponse()

        // Then
        
        let result = await perform(request: request, testResponse: response)
        
        switch result {
        case .success:
            Issue.record("Expecting api call to fail")
        case let .failure(error):
            guard let apiClientError = error as? APIClientError else {
                Issue.record("Expecting `APIClientError`")
                return
            }
            #expect(apiClientError == APIClientError.invalidResponse)
        }
    }
    
    @Test(
        "Valid Responses & Success Status Code - [EmptyResponse|EmptyErrorResponse] - Should Succeed",
        arguments: [
            TestResponse(data: "".data(using: .utf8), statusCode: 200),
            TestResponse(data: "{}".data(using: .utf8), statusCode: 200),
            TestResponse(data: try! JSONEncoder().encode(MockResponse(someField: "SomeValue")), statusCode: 200)
        ]
    )
    func validEmptyResponsesWithSuccessStatusCode(_ response: TestResponse) async throws {

        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()

        // Then

        let result = await perform(request: request, testResponse: response)
        
        switch result {
        case .success: break
        case .failure: Issue.record("Expecting api call to succeed")
        }
    }
    
    @Test(
        "Valid Responses & Failure Status Code - [EmptyResponse|EmptyErrorResponse] - Should Fail with EmptyErrorResponse",
        arguments: [
            TestResponse(data: "".data(using: .utf8), statusCode: 404),
            TestResponse(data: "{}".data(using: .utf8), statusCode: 500),
            TestResponse(data: try! JSONEncoder().encode(MockResponse(someField: "SomeValue")), statusCode: 456)
        ]
    )
    func validEmptyResponsesWithFailureStatusCode(_ response: TestResponse) async throws {

        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()

        // Then

        let result = await perform(request: request, testResponse: response)
        
        switch result {
        case .success:
            Issue.record("Expecting api call to fail")
        case let .failure(error):
            #expect(error is EmptyErrorResponse)
        }
    }
}

// MARK: - Helpers

private extension APIClientTests {

    func perform<RequestType: Request>(
        request: RequestType,
        testResponse: TestResponse
    ) async -> Result<RequestType.ResponseType, Error> {
        await withCheckedContinuation { continuation in
            let mockURLSession = MockURLSession(
                nextData: testResponse.data,
                nextResponse: testResponse.response,
                nextError: testResponse.error
            )

            APIClient(apiContext: MockAPIContext(), urlSession: mockURLSession, coder: Coder()).perform(request) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
