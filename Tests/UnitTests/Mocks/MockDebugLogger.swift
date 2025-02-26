//
//  MockDebugLogger.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

@testable import AdyenNetworking

class MockDebugLogger: DebugLogging {
    
    var printStatements: [Any] = []
    
    func print(_ items: Any..., separator: String, terminator: String, fileId: String) {
        guard Logging.isEnabled else { return }
        printStatements += items
    }
}
