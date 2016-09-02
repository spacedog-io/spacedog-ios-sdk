//
//  SDResponse.swift
//  caremendriver
//
//  Created by flav on 29/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDResponse: Mappable {
    
    public var success: Bool?
    public var status: Int?
    public var id: String?
    public var type: String?
    public var location: String?
    public var version: Int?
    public var error: SDError?
    
    required public init?(_ map: Map) {
        
    }
    
    public init() {}
    
    public init(success: Bool, status: Int, error: SDError) {
        self.success = success
        self.status = status
        self.error = error
    }
    
    public func mapping(map: Map) {
        
        success    <- map["success"]
        status     <- map["status"]
        id         <- map["id"]
        type       <- map["type"]
        location   <- map["location"]
        version    <- map["version"]
        error      <- map["error"]
    }
}