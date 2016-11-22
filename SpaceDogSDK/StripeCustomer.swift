//
//  StripeCustomer.swift
//  caremenpassenger
//
//  Created by flav on 22/11/2016.
//  Copyright © 2016 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

public class StripeCustomer: Mappable {
    
    public var id: String?
    public var email: String?
    public var defaultSource: String?
    public var cards: [Card]?
    
    public init() {}
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        id      <- map["id"]
        email   <- map["email"]
        defaultSource <- map["default_source"]
        cards   <- map["sources.data"]
    }
}
