//
//  SDContext.swift
//  caremen-robot
//
//  Created by philippe.rolland on 13/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation

public class SDContext {
    let instanceId: String
    var credentials: SDCredentials?
    
    public init(instanceId: String) {
        self.instanceId = instanceId
    }
    
    public func setLogged(with credentials: SDCredentials) -> Void {
        self.credentials = credentials
    }
    
    public func isLogged() -> Bool {
        return self.credentials != nil
    }
}
