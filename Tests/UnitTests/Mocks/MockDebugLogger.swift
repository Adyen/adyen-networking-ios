//
//  MockDebugLogger.swift
//  AdyenNetworking
//
//  Created by Alexander Guretzki on 26/02/2025.
//

@testable import AdyenNetworking

class MockDebugLogger: DebugLogging {
    
    struct Log: Equatable {
        let content: String
        let fileId: String
        
        init(_ content: String, fileId: String = "AdyenNetworking/APIClient.swift") {
            self.content = content
            self.fileId = fileId
        }
    }
    
    var logs: [Log] = []
    
    func print(_ items: Any..., separator: String, terminator: String, fileId: String) {
        guard Logging.isEnabled else { return }
        logs += items.map { .init("\($0)", fileId: fileId) }
    }
}
