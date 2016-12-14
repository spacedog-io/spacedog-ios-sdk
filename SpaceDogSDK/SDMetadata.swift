//
//  SDMetadata.swift
//  caremenpassenger
//
//  Created by flav on 02/12/2016.
//  Copyright © 2016 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDMetadata: Mappable {
    
    public var createdBy: String?
    public var updatedBy: String?
    public var createdAt: NSDate?
    public var updatedAt: NSDate?
    public var id: String?
    public var type: String?
    public var version: Int?
    public var sort: [Double]?
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        createdBy  <- map["createdBy"]
        updatedBy  <- map["updatedBy"]
        createdAt  <- (map["createdAt"], DateISO8601Transform())
        updatedAt  <- (map["updatedAt"], DateISO8601Transform())
        id         <- map["id"]
        type       <- map["type"]
        version    <- map["version"]
        sort       <- map["sort"]
    }
}
