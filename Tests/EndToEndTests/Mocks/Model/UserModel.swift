//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

internal struct UserModel: Codable {
    
    internal enum Status: String, Codable {
        case active
        case inactive
    }
    
    let id: Int
    let name: String
    let email: String
    let gender: Gender
    let status: Status
}

internal enum Gender: String, Codable {
    case female
    case male
}
