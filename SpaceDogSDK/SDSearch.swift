//
//  SDSearch.swift
//  caremendriver
//
//  Created by flav on 30/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

open class SDSearch<T: Mappable>: Mappable {
    
    open var took: Int?
    open var total: Int?
    open var results: [T]?

    required public init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        took   <- map["took"]
        total   <- map["total"]
        results   <- map["results"]
    }
}
