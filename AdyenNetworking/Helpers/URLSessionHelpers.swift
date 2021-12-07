//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

internal struct URLSessionSuccess {
    internal let data: Data
    
    internal let response: HTTPURLResponse
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
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(URLSessionSuccess(data: data, response: response)))
            } else {
                completion(.failure(APIClientError.invalidResponse))
            }
        }
    }
    
}
