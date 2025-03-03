//
//  DebugLogger.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

import Foundation

internal struct DebugLogger: DebugLogging {
    
    func print(_ items: Any..., separator: String, terminator: String, fileId: String) {
        guard Logging.isEnabled else { return }
        let moduleName = fileId.split(separator: "/").first ?? "AdyenNetworking"
        
        let items = [
            ISO8601DateFormatter().string(from: Date()),
            "[\(moduleName)]"
        ] + items
        
        var idx = items.startIndex
        let endIdx = items.endIndex
        
        repeat {
            Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
            idx += 1
        } while idx < endIdx
    }
}
