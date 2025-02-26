//
//  AdyenDebugging.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

import Foundation

internal protocol DebugLogging {
    
    func print(_ items: Any..., separator: String, terminator: String, fileId: String)
}

// MARK: - Convenience Extensions

internal extension DebugLogging {
    
    func print(_ items: Any..., fileId: String = #fileID) {
        guard Logging.isEnabled else { return }
        print(items, separator: " ", terminator: "\n", fileId: fileId)
    }
    
    func printAsJSON(_ dictionary: [String : Any], fileId: String = #fileID) {
        guard Logging.isEnabled else { return }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
            printAsJSON(jsonData, fileId: fileId)
        } catch {
            print(dictionary, fileId: fileId)
        }
    }
    
    func printAsJSON(_ data: Data, fileId: String = #fileID) {
        guard Logging.isEnabled else { return }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

            print(jsonString, fileId: fileId)
        } catch {
            if let string = String(data: data, encoding: .utf8) {
                print(string, fileId: fileId)
            }
        }
    }
}

private extension JSONSerialization.WritingOptions {
    static var jsonOptions: Self {
        if #available(iOS 13.0, *) {
            return [.prettyPrinted, .withoutEscapingSlashes]
        } else {
            return [.prettyPrinted]
        }
    }
}
