//
//  SDBatch.swift
//  caremenpassenger
//
//  Created by flav on 09/12/2016.
//  Copyright © 2016 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

open class SDBatch: Mappable {
    
    open var success: Bool?
    open var status: Int?
    open var responses: [AnyObject]?
    open var error: SDError?
    
    required public init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        success       <- map["success"]
        status        <- map["status"]
        responses     <- map["responses"]
        error         <- map["error"]
    }
}
