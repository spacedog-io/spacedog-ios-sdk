//
//  SDResponse.swift
//  caremendriver
//
//  Created by flav on 29/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

open class SDResponse: Mappable {
    
    open var success: Bool?
    open var status: Int?
    open var id: String?
    open var type: String?
    open var location: String?
    open var version: Int?
    open var error: SDError?
    
    required public init?(map: Map) {
        
    }
    
    public init() {}
    
    public init(success: Bool, status: Int, error: SDError) {
        self.success = success
        self.status = status
        self.error = error
    }
    
    open func mapping(map: Map) {
        
        success    <- map["success"]
        status     <- map["status"]
        id         <- map["id"]
        type       <- map["type"]
        location   <- map["location"]
        version    <- map["version"]
        error      <- map["error"]
    }
}
