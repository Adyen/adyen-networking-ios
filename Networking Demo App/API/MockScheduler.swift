//
//  MockScheduler.swift
//  Networking Demo App
//
//  Created by James McGuire on 05/10/2022.
//

import AdyenNetworking

internal struct MockScheduler: Scheduler {
    let maxCount: Int
    let onSchedule: () -> Void
    
    func schedule(_ currentCount: UInt, closure: @escaping () -> Void) -> Bool {
        onSchedule()
        
        guard currentCount < maxCount else { return true }
        
        closure()
        
        return false
    }
}
