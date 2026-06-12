//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Provides control over SDK logging.
public enum Logging {
    /// Indicates whether to enable printing to the console.
    public static var isEnabled: Bool = false
}

// MARK: - Backwards compatible global print

@_spi(AdyenInternal)
public func adyenPrintAsJSON(_ data: Data, _ category: LogCategory = .request) {
    let logger = category == .request ? DebugLogger.request : DebugLogger.response
    logger.printAsJSON(data)
}
