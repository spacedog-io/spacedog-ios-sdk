//
//  Card.swift
//  caremen-stripe
//
//  Created by philippe.rolland on 09/11/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation
import ObjectMapper

open class Card: Mappable {
    
    open var id: String?
    open var brand: String?
    open var name: String?
    open var last4: String?
    open var expMonth: Int?
    open var expYear: Int?
    open var label: String?
    
    public init() {}

    required public init?(map: Map) {
    }
    
    open func mapping(map: Map) {
        id            <- map["id"]
        brand         <- map["brand"]
        name          <- map["name"]
        label         <- map["metadata.description"]
        last4         <- map["last4"]
        expMonth      <- map["exp_month"]
        expYear       <- map["exp_year"]
    }
}
