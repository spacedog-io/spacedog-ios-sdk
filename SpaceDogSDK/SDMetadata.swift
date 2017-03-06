//
//  SDMetadata.swift
//  caremenpassenger
//
//  Created by flav on 02/12/2016.
//  Copyright © 2016 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

open class SDMetadata: Mappable {
    
    open var createdBy: String?
    open var updatedBy: String?
    open var createdAt: Date?
    open var updatedAt: Date?
    open var id: String?
    open var type: String?
    open var version: Int?
    open var sort: [Double]?
    
    required public init?(map: Map) {
    }
    
    open func mapping(map: Map) {
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
