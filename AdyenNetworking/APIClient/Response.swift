//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Describes an API response.
public protocol Response: Decodable { }

/// Represents an API download response.
///
/// The `url` property provides the temporary path to the downloaded file.
public struct DownloadResponse: Response {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    enum CodingKeys: CodingKey {
        case url
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
    }
}

/// Represents an empty API response.
public struct EmptyResponse: Response {
    public init() { }
}

/// Describes an API Error response.
public protocol ErrorResponse: Response, Error { }

/// Represents an empty API Error response.
public struct EmptyErrorResponse: ErrorResponse { }
