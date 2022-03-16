//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

internal struct URLSessionSuccess {
    internal let data: Data
    
    internal let statusCode: Int
    
    internal let headers: [String: String]
    
    internal init(data: Data?, response: URLResponse?) throws {
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse,
              let headers = httpResponse.allHeaderFields as? [String: String] else {
                  throw APIClientError.invalidResponse
        }
        
        self.data = data
        self.headers = headers
        self.statusCode = httpResponse.statusCode
    }
}

/// :nodoc:
internal extension URLSession {

    /// :nodoc:
    func dataTask(
        with urlRequest: URLRequest,
        completion: @escaping ((Result<URLSessionSuccess, Error>) -> Void)
    ) -> URLSessionDataTask {
        dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.init(catching: { try URLSessionSuccess(data: data, response: response) }))
            }
        }
    }
    
}
