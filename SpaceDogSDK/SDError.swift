//
//  SDError.swift
//  caremendriver
//
//  Created by flav on 30/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

open class SDError: Mappable {
    
    open var type: String?
    open var message: String?
    open var cause: String?
    open var code: String?

    required public init?(map: Map) {
    }
    
    public init() {}
    
    public init(type: String, message: String) {
        self.type = type
        self.message = message
    }
    
    
    open func mapping(map: Map) {
        type        <- map["type"]
        message     <- map["message"]
        cause       <- map["cause.message"]
        code        <- map["code"]
    }
}
