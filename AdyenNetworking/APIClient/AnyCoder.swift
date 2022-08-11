//
//  File.swift
//  
//
//  Created by Emrah Akgul on 05/08/2022.
//

import Foundation

public protocol AnyCoder {
    
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
    func encode<T: Encodable>(_ value: T) throws -> Data
}
