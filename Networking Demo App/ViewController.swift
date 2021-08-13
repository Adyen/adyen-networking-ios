//
//  ViewController.swift
//  Networking Demo App
//
//  Created by Mohamed Eldoheiri on 7/28/21.
//

import UIKit
import AdyenNetworking

class ViewController: UIViewController {
    
    let apiClient = APIClient(apiContext: APIContext())

    override func viewDidLoad() {
        super.viewDidLoad()
        Logging.isEnabled = true
        let request = GetUsersRequest()
        apiClient.perform(request) { result in
            switch result {
            case let .success(response):
                print(response)
            case let .failure(error):
                print(error)
            }
        }
        
        let name = UUID().uuidString
        let newUser = UserModel(id: Int.random(in: 0...1000),
                                name: name,
                                email: "\(name)@gmail.com",
                                gender: .female,
                                status: .active)
        let createRequest = CreateUsersRequest(userModel: newUser)
        apiClient.perform(createRequest) { result in
            switch result {
            case let .success(response):
                print(response)
            case let .failure(error):
                print(error)
            }
        }
        
        let name1 = UUID().uuidString
        let newUser1 = UserModel(id: Int.random(in: 0...1000),
                                name: name1,
                                email: "\(name1)@gmail.com",
                                gender: .female,
                                status: .active)
        let createRequest1 = RequestWithEmptyResponse(userModel: newUser1)
        apiClient.perform(createRequest1) { result in
            switch result {
            case let .success(response):
                print(response)
            case let .failure(error):
                print(error)
            }
        }
    }


}

