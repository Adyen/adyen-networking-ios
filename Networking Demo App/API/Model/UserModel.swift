//
//  UserModel.swift
//  Networking Demo App
//
//  Created by Mohamed Eldoheiri on 7/30/21.
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
