//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import func Darwin.fputs
import Foundation
import OSLog

/// Provides control over SDK logging.
public enum Logging {
    /// Indicates whether to enable printing to the console.
    public static var isEnabled: Bool = false
}

extension Logging {
    
    @available(iOS 14.0, *)
    static var logger: Logger { return Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.adyen.Adyen", category: "AdyenNetworking") }
    
    static func log(_ message: String, as level: OSLogType = .info) {
        guard Logging.isEnabled else { return }
        
        if #available(iOS 14.0, *) {
            logger.log(level: level, "\(message)")
        } else {
            print(message)
        }
    }
}

extension Dictionary where Key == String {
    
    var asJsonString: String? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: self, options: jsonOptions)
        else {
            return nil
        }
        
        return String(data: jsonData, encoding: .utf8)
    }
}

extension Data {
    
    var asJsonString: String? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: jsonOptions)
        else {
            return nil
        }
        
        return String(data: jsonData, encoding: .utf8)
    }
}

private var jsonOptions: JSONSerialization.WritingOptions {
    
    if #available(iOS 13.0, *) {
        return [.prettyPrinted, .withoutEscapingSlashes]
    } else {
        return [.prettyPrinted]
    }
}
