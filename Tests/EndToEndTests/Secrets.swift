//
//  Secrets.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 18/07/2025.
//

import Foundation

// We're using a class to internally figure out which bundle to load the secrets from
class Secrets {
    private init() {}
    
    static var goRestAuthBearer: String {
        guard let bearer = stringValue(for: "GO_REST_AUTH_BEARER") else {
            fatalError("GO_REST_AUTH_BEARER has to be provided via DevSecrets.xcconfig")
        }
        
        var characterSet = CharacterSet()
        characterSet.insert("\"")
        return bearer.trimmingCharacters(in: characterSet) // Making sure we don't have double ""
    }
}

// MARK: - Helpers

private extension Secrets {
    static func value<T>(for key: String) -> T? {
        let bundle = Bundle(for: Self.self)
        return bundle.infoDictionary?[key] as? T
    }
    
    static func stringValue(for key: String) -> String? {
        return value(for: key)
    }
}
