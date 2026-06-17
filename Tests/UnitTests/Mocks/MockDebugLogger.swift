//
//  MockDebugLogger.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

@testable import AdyenNetworking

class MockDebugLogger: DebugLogging {
    
    var logs: [String] = []
    
    func print(_ message: () -> String) {
        guard Logging.isEnabled else { return }
        logs.append(message())
    }
}
