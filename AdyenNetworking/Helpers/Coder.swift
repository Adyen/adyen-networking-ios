//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// An object that provides helper functions for coding and decoding responses.
/// :nodoc:
public class Coder: AnyCoder {
    
    public init() {}
    
    // MARK: - Decoding
    
    /// :nodoc:
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Encoding
    
    /// :nodoc:
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
    
    // MARK: - Private
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
