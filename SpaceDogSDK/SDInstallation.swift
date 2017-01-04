//
//  SDInstallation.swift
//  caremenpassenger
//
//  Created by flav on 03/01/2017.
//  Copyright © 2017 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDInstallation: Mappable {
    
    public var pushService: String?
    public var appId: String?
    public var token: String?
    public var endpoint: String?
    public var tags: [SDTag]?
    public var meta: SDMetadata?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        pushService <- map["pushService"]
        appId       <- map["appId"]
        token       <- map["token"]
        endpoint    <- map["endpoint"]
        tags        <- map["tags"]
        meta        <- map["meta"]
    }
}

public class SDTag: Mappable {
    
    public var key: String?
    public var value: String?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        key     <- map["key"]
        value   <- map["value"]
    }
}
