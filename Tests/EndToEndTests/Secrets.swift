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
    
    static private func value<T>(for key: String) -> T? {
        let bundle = Bundle(for: Self.self)
        return bundle.infoDictionary?[key] as? T
    }
    
    static var goRestAuthBearer: String {
        var bearer = value(for: "GO_REST_AUTH_BEARER") ?? ""
        
        var characterSet = CharacterSet()
        characterSet.insert("\"")
        bearer = bearer.trimmingCharacters(in: characterSet)
        
        return bearer
    }
}
