//
//  SDCredentials.swift
//  caremen-robot
//
//  Created by philippe.rolland on 13/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation


public class SDCredentials {
    let userId: String
    let userToken: String
    let expiresIn: Int
    let acquired: NSDate
    
    public init(userId: String, userToken: String, expiresIn: Int, acquired: NSDate) {
        self.userId = userId
        self.userToken = userToken
        self.expiresIn = expiresIn
        self.acquired = acquired
    }
}
