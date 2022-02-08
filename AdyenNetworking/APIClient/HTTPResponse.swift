//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

public struct HTTPResponse<R: Response> {
    
    public let headers: [String: String]
    
    public let statusCode: Int
    
    public let response: R
    
}
