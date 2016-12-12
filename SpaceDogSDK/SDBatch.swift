//
//  SDBatch.swift
//  caremenpassenger
//
//  Created by flav on 09/12/2016.
//  Copyright © 2016 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDBatch: Mappable {
    
    public var success: Bool?
    public var status: Int?
    public var responses: [AnyObject]?
    public var error: SDError?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        success       <- map["success"]
        status        <- map["status"]
        responses     <- map["responses"]
        error         <- map["error"]
    }
}
