//
//  SDSearch.swift
//  caremendriver
//
//  Created by flav on 30/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDSearch<T: Mappable>: Mappable {
    
    public var took: Int?
    public var total: Int?
    public var results: [T]?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        took   <- map["took"]
        total   <- map["total"]
        results   <- map["results"]
    }
}