//
//  StripeCustomer.swift
//  caremenpassenger
//
//  Created by flav on 22/11/2016.
//  Copyright © 2016 In-tact. All rights reserved.
//

import Foundation
import ObjectMapper

open class StripeCustomer: Mappable {
    
    open var id: String?
    open var email: String?
    open var defaultSource: String?
    open var cards: [Card]?
    
    public init() {}
    
    required public init?(map: Map) {
    }
    
    open func mapping(map: Map) {
        id              <- map["id"]
        email           <- map["email"]
        defaultSource   <- map["default_source"]
        cards           <- map["sources.data"]
    }
    
    open func getDefaultCard() -> Card? {
        let defautSourceId = self.defaultSource ?? ""
        return self.cards?.filter({ $0.id == defautSourceId }).first
    }
}
