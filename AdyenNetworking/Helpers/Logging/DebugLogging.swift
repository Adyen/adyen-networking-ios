//
//  AdyenDebugging.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

import Foundation

public enum LogCategory: String {
    case request
    case response
}

internal protocol DebugLogging {

    func print(_ message: () -> String)
}

// MARK: - Convenience Extensions

internal extension DebugLogging {

    func print(_ message: @autoclosure () -> String) {
        guard Logging.isEnabled else { return }
        print(message)
    }

    func printAsJSON(_ dictionary: [String: Any], label: String = "") {
        guard Logging.isEnabled else { return }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .jsonOptions)
            printAsJSON(jsonData, label: label)
        } catch {
            print(label.isEmpty ? "Failed to serialize dictionary: \(error)" : "Failed to serialize dictionary for \(label): \(error)")
            print(label.isEmpty ? "\(dictionary)" : "\(label): \(dictionary)")
        }
    }

    func printAsJSON(_ data: Data, label: String = "") {
        guard Logging.isEnabled else { return }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .jsonOptions)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
            print(label.isEmpty ? jsonString : "\(label): \(jsonString)")
        } catch {
            print(label.isEmpty ? "Failed to serialize data: \(error)" : "Failed to serialize data for \(label): \(error)")
            if let string = String(data: data, encoding: .utf8) {
                print(label.isEmpty ? "Raw data: \(string)" : "\(label): Raw data: \(string)")
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
