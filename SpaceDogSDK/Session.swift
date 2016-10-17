//
//  Session.swift
//  caremendriver
//
//  Created by Aurelien Gustan on 05/09/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

public class SDSession: Mappable {
    
    var accessToken: String?
    var expiresIn: Int?
    var credentialsId: String?
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        accessToken     <- map["accessToken"]
        expiresIn       <- map["expiresIn"]
        credentialsId   <- map["credentials.id"]

    }
}
