//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
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
