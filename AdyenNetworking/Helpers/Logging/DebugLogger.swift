//
//  DebugLogger.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

import Foundation
import os.log

internal struct DebugLogger: DebugLogging {

    internal static let request = DebugLogger(category: .request)
    internal static let response = DebugLogger(category: .response)

    internal static func shared(for category: LogCategory) -> any DebugLogging {
        category == .request ? request : response
    }

    private let osLog: OSLog

    private init(category: LogCategory) {
        osLog = OSLog(subsystem: "com.adyen.networking", category: category.rawValue)
    }

    func print(_ message: () -> String) {
        guard Logging.isEnabled else { return }
        os_log("%{public}@", log: osLog, type: .debug, message())
    }
}
