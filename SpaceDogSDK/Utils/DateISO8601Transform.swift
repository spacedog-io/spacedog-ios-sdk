//
//  DateISO8601Transform.swift
//  caremendriver
//
//  Created by flav on 26/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import ObjectMapper

open class DateISO8601Transform: TransformType {
    public typealias Object = Date
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            return dateString.dateFromISO8601 as Date?
        }
        return nil
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return date.iso8601
        }
        return nil
    }
}
