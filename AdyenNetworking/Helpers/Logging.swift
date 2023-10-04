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
    
    static var apiClient: AdyenLogger {
        .init(subsystem: "AdyenNetworking", category: "APIClient")
    }
}

struct AdyenLogger {
    let subsystem: String
    let category: String
    
    func log(_ message: String, as level: OSLogType = .debug) {
        guard Logging.isEnabled else { return }
        
        if #available(iOS 17.0, *) {
            Logger(subsystem: subsystem, category: category).log(level: level, "\(message)")
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
