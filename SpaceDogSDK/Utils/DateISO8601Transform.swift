//
//  DateISO8601Transform.swift
//  caremendriver
//
//  Created by flav on 26/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

public class DateISO8601Transform: TransformType {
    public typealias Object = NSDate
    public typealias JSON = String
    
    public init() {}
    
    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let dateString = value as? String {
            return dateString.dateFromISO8601
        }
        return nil
    }
    
    public func transformToJSON(value: NSDate?) -> String? {
        if let date = value {
            return date.iso8601
        }
        return nil
    }
}
