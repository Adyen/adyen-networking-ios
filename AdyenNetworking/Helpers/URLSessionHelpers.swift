//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

internal struct URLSessionSuccess {
    internal let data: Data
    
    internal let response: HTTPURLResponse
    
    internal init(data: Data?, response: URLResponse?) throws {
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse else {
                  throw APIClientError.invalidResponse
        }
        
        self.data = data
        self.response = httpResponse
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
