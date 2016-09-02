//
//  SDError.swift
//  caremendriver
//
//  Created by flav on 30/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDError: Mappable {
    
    public var type: String?
    public var message: String?
    
    required public init?(_ map: Map) {
    }
    
    public init() {}
    
    public init(type: String, message: String) {
        self.type = type
        self.message = message
    }
    
    
    public func mapping(map: Map) {
        type        <- map["type"]
        message     <- map["message"]
    }
}