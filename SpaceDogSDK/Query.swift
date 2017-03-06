//
//  Query.swift
//  caremen-robot
//
//  Created by philippe.rolland on 20/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation

open class Query {

    public enum Order: String {
        case Asc = "asc", Desc = "desc"
    }
    
    fileprivate var map: [String: Any]
    
    public init() {
        self.map = [String: Any]()
    }
    
    open func limit(_ size: Int) -> Query {
        map["size"] = size as Any?
        return self
    }

    open func source(_ source: Bool) -> Query {
        self.map["_source"] = source as Any?
        return self
    }
    
    open func method(_ method: String) -> Query {
        self.map["method"] = method as Any?
        return self
    }
    
    open func path(_ path: String) -> Query {
        self.map["path"] = path as Any?
        return self
    }
    
    open func content(_ content: [String: Any]) -> Query {
        self.map["content"] = content as Any?
        return self
    }
    
    open func closestTo(path: String, lat: Double, lng: Double) -> Query {
        self.map["sort"] = [
            ["_geo_distance" : ["order": "asc", "unit": "km", "distance_type": "plane", path : ["lat" : lat , "lon" : lng]]]
        ]
        return self
    }
    
    open func sort(path: String, order: Order = Order.Asc) -> Query {
        self.map["sort"] = [[path: ["order": order.rawValue]]]
        return self
    }
    
    open func term(_ term: [String: [String: String]]) -> Query {
        self.map["query"] = term as AnyObject?
        return self
    }
    
    open func terms(_ terms: [String: [String: [String]]]) -> Query {
        self.map["query"] = terms as AnyObject?
        return self
    }
    
    open func filter(_ filters: [String: Any]...) -> Query {
        self.map["query"] = ["bool" : ["filter" : filters]]
        return self
    }
    
    open func combinaison(must: [String: [String: String]], mustNot: [String: [String: String]]) -> Query {
        self.map["query"] = ["bool" : ["must" : [must], "must_not": [mustNot]]]
        return self
    }
    
    open func combinaison(must: [[String: [String: String]]], mustNot: [[String: [String: String]]]) -> Query {
        self.map["query"] = ["bool" : ["must" : must, "must_not": mustNot]]
        return self
    }
    
    open func must(_ must: [String: [String: String]]...) -> Query {
        self.map["query"] = ["bool" : ["must" : must]]
        return self
    }
    
    open func build() -> [String: Any] {
        return self.map
    }

    
    open static func term(path: String, value: String) -> [String: [String: String]] {
        return ["term" : [path : value]]
    }
    
    open static func terms(path: String, values: [String]) -> [String: [String: [String]]] {
        return ["terms" : [path : values]]
    }
    
    open static func exists(path: String) -> [String: [String: String]] {
        return ["exists" : ["field" : path]]
    }
    
    open static func range(path: String, comparator: String, compareTo: String) -> [String: [String: [String: String]]] {
        return ["range" : [path : [comparator : compareTo]]]
    }
}
