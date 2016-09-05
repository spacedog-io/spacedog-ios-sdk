//
//  Session.swift
//  caremendriver
//
//  Created by Aurelien Gustan on 05/09/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

class Session: Mappable {
    
    var accessToken: String?
    var expiresIn: Int?
    
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        accessToken   <- map["accessToken"]
        expiresIn     <- map["expiresIn"]
    }
}