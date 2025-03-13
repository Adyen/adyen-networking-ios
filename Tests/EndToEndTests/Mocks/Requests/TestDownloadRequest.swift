//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import AdyenNetworking

internal struct DownloadError: ErrorResponse {
    
}

internal struct TestDownloadRequest: Request {
    typealias ResponseType = DownloadResponse
    
    typealias ErrorResponseType = DownloadError
    
    var delegate: URLSessionDownloadDelegate?
    
    var path: String = "images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"
    
    var counter: UInt = 0
    
    var headers: [String : String] = [:]
    
    var queryParameters: [URLQueryItem] = []
    
    var method: HTTPMethod = .get
    
    private enum CodingKeys: CodingKey {}
}

@available(iOS 15.0.0, *)
internal struct TestAsyncDownloadRequest: AsyncDownloadRequest {
    typealias ResponseType = DownloadResponse
    
    typealias ErrorResponseType = DownloadError
    
    var onProgressUpdate: ((Double) -> Void)?
    
    var delegate: URLSessionDownloadDelegate?
    
    var path: String = "images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"
    
    var counter: UInt = 0
    
    var headers: [String : String] = [:]
    
    var queryParameters: [URLQueryItem] = []
    
    var method: HTTPMethod = .get
    
    private enum CodingKeys: CodingKey {}
}
