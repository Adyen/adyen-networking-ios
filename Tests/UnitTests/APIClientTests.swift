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
    
    @Test
    func client_fails_onEmptyUrlSessionResponse() async throws {

        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        let response = TestResponse()

        // Then
        
        let result = await perform(
            request: request,
            testResponse: response
        )
        
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
    func client_succeeds_onValidEmptyResponse_withSuccessStatusCode(_ response: TestResponse) async throws {

        let expectedLogs = [
            "---- Request (/) ----",
            "---- Request base url (/) ----",
            "https://www.adyen.com/",
            "---- Request Headers (/) ----",
            "{}",
            "---- Request query (/) ----",
            "{}",
            "---- Response Code (/) ----",
            "\(response.response!.statusCode)",
            "---- Response Headers (/) ----",
            "{}",
            "---- Response (/) ----",
            "\(String(data: response.data!, encoding: .utf8)!)"
        ] as [Any]
        
        Logging.isEnabled = true
        let debugLogger = MockDebugLogger()
        
        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        
        // Then

        let result = await perform(
            request: request,
            testResponse: response,
            debugLogger: debugLogger
        )
        
        print(debugLogger.printStatements)
        
        switch result {
        case .success: break
        case .failure: Issue.record("Expecting api call to succeed")
        }
        
        #expect(debugLogger.printStatements.map { "\($0)" } == expectedLogs.map { "\($0)"})
    }
    
    @Test(
        "Valid Responses & Failure Status Code - [EmptyResponse|EmptyErrorResponse] - Should Fail with EmptyErrorResponse",
        arguments: [
            TestResponse(data: "".data(using: .utf8), statusCode: 404),
            TestResponse(data: "{}".data(using: .utf8), statusCode: 500),
            TestResponse(data: try! JSONEncoder().encode(MockResponse(someField: "SomeValue")), statusCode: 456)
        ]
    )
    func client_fails_onValidEmptyResponse_withFailureStatusCode(_ response: TestResponse) async throws {

        let expectedLogs = [
            "---- Request (/) ----",
            "---- Request base url (/) ----",
            "https://www.adyen.com/",
            "---- Request Headers (/) ----",
            "{}",
            "---- Request query (/) ----",
            "{}",
            "---- Response Code (/) ----",
            "\(response.response!.statusCode)",
            "---- Response Headers (/) ----",
            "{}",
            "---- Response (/) ----",
            "\(String(data: response.data!, encoding: .utf8)!)"
        ] as [Any]
        
        Logging.isEnabled = true
        let debugLogger = MockDebugLogger()
        
        let request = MockRequest<EmptyResponse, EmptyErrorResponse>()
        
        // Then

        let result = await perform(
            request: request,
            testResponse: response,
            debugLogger: debugLogger
        )
        
        switch result {
        case .success:
            Issue.record("Expecting api call to fail")
        case let .failure(error):
            #expect(error is EmptyErrorResponse)
        }
        
        #expect(debugLogger.printStatements.map { "\($0)" } == expectedLogs.map { "\($0)"})
    }
    
    @Test
    func client_succeeds_onValidMockResponse_withSuccessStatusCode() async throws {

        let expectedLogs = [
            "---- Request (/) ----",
            "---- Request base url (/) ----",
            "https://www.adyen.com/",
            "---- Request Headers (/) ----",
            "{\"HeaderName\":\"HeaderValue\"}",
            "---- Request query (/) ----",
            "{\"name\":\"value\"}",
            "---- Response Code (/) ----",
            "200",
            "---- Response Headers (/) ----",
            "{}",
            "---- Response (/) ----",
            "{\"someField\":\"SomeValue\"}"
        ] as [Any]
        
        let expectedResponse = MockResponse(someField: "SomeValue")
        
        Logging.isEnabled = true
        let debugLogger = MockDebugLogger()
        
        let request = MockRequest<MockResponse, EmptyErrorResponse>(
            queryParameters: [.init(name: "name", value: "value")],
            headers: ["HeaderName": "HeaderValue"]
        )
        
        let testResponse = TestResponse(data: try! JSONEncoder().encode(expectedResponse), statusCode: 200)
        
        // Then

        let result = await perform(
            request: request,
            testResponse: testResponse,
            debugLogger: debugLogger
        )
        
        switch result {
        case let .success(response):
            #expect(response == expectedResponse)
        case .failure:
            Issue.record("Expecting api call to succeed")
        }
        
        #expect(debugLogger.printStatements.map { "\($0)" } == expectedLogs.map { "\($0)"})
    }
}

// MARK: - Helpers

private extension APIClientTests {

    func perform<RequestType: Request>(
        request: RequestType,
        testResponse: TestResponse,
        debugLogger: any DebugLogging = MockDebugLogger()
    ) async -> Result<RequestType.ResponseType, Error> {
        await withCheckedContinuation { continuation in
            let mockURLSession = MockURLSession(
                nextData: testResponse.data,
                nextResponse: testResponse.response,
                nextError: testResponse.error
            )

            APIClient(
                apiContext: MockAPIContext(),
                urlSession: mockURLSession,
                debugLogger: debugLogger
            ).perform(request) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
