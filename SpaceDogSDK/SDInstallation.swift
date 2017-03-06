//
//  SDInstallation.swift
//  caremenpassenger
//
//  Created by flav on 03/01/2017.
//  Copyright © 2017 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

open class SDInstallation: Mappable {
    
    open var pushService: String?
    open var appId: String?
    open var token: String?
    open var endpoint: String?
    open var tags: [SDTag]?
    open var meta: SDMetadata?
    
    required public init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        pushService <- map["pushService"]
        appId       <- map["appId"]
        token       <- map["token"]
        endpoint    <- map["endpoint"]
        tags        <- map["tags"]
        meta        <- map["meta"]
    }
}

open class SDTag: Mappable {
    
    open var key: String?
    open var value: String?
    
    required public init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        key     <- map["key"]
        value   <- map["value"]
    }
}
