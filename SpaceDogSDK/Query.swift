//
//  Query.swift
//  caremen-robot
//
//  Created by philippe.rolland on 20/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation

public class Query {

    public enum Order: String {
        case Asc = "asc", Desc = "desc"
    }
    
    private var map: [String: AnyObject]
    
    public init() {
        self.map = [String: AnyObject]()
    }
    
    public func limit(size: Int) -> Query {
        map["size"] = size
        return self
    }
    
    public func closestTo(path path: String, lat: Double, lng: Double) -> Query {
        self.map["sort"] = [
            ["_geo_distance" : ["order": "asc", "unit": "km", "distance_type": "plane", path : ["lat" : lat , "lon" : lng]]]
        ]
        return self
    }
    
    public func sort(path path: String, order: Order? = Order.Asc) -> Query {
        self.map["sort"] = [[path: ["order": order?.rawValue]]]
        return self
    }
    
    public func term(term: [String: [String: String]]) -> Query {
        self.map["query"] = term
        return self
    }
    
    public func terms(terms: [String: [String: [String]]]) -> Query {
        self.map["query"] = terms
        return self
    }
    
    public func filter(filters: [String: AnyObject]...) -> Query {
        self.map["query"] = ["bool" : ["filter" : filters]]
        return self
    }
    
    public func combinaison(must must: [String: [String: String]], mustNot: [String: [String: String]]) -> Query {
        self.map["query"] = ["bool" : ["must" : [must], "must_not": [[mustNot]]]]
        return self
    }
    
    public func build() -> [String: AnyObject] {
        return self.map
    }

    
    public static func term(path path: String, value: String) -> [String: [String: String]] {
        return ["term" : [path : value]]
    }
    
    public static func terms(path path: String, values: [String]) -> [String: [String: [String]]] {
        return ["terms" : [path : values]]
    }
    
    public static func exists(path path: String) -> [String: [String: String]] {
        return ["exists" : ["field" : path]]
    }
    
    public static func range(path path: String, comparator: String, compareTo: String) -> [String: [String: [String: String]]] {
        return ["range" : [path : [comparator : compareTo]]]
    }
}
