//
//  Card.swift
//  caremen-stripe
//
//  Created by philippe.rolland on 09/11/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation
import ObjectMapper

public class Card: Mappable {
    
    public var id: String?
    public var brand: String?
    public var name: String?
    public var last4: String?
    public var expMonth: Int?
    public var expYear: Int?
    public var label: String?
    
    public init() {}

    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        id            <- map["id"]
        brand         <- map["brand"]
        name          <- map["name"]
        label         <- map["metadata.description"]
        last4         <- map["last4"]
        expMonth      <- map["exp_month"]
        expYear       <- map["exp_year"]
    }
}
