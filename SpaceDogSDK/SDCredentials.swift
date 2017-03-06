//
//  SDCredentials.swift
//  caremen-robot
//
//  Created by philippe.rolland on 13/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation


open class SDCredentials : CustomStringConvertible {
    let userId: String
    let userToken: String
    let userEmail: String
    let expiresIn: Int
    let acquired: Date
    
    public init(userId: String, userToken: String, userEmail: String, expiresIn: Int, acquired: Date) {
        self.userId = userId
        self.userToken = userToken
        self.userEmail = userEmail
        self.expiresIn = expiresIn
        self.acquired = acquired
    }
    
    open var description: String {
        return "{userId: \(userId), userToken: \(userToken), userEmail: \(userEmail), expiresIn: \(expiresIn), acquired: \(acquired) }"
    }
}
