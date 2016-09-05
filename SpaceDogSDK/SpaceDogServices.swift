//
//  SpaceDogServices.swift
//  caremendriver
//
//  Created by flav on 29/08/2016.
//  Copyright © 2016 intact. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import AlamofireObjectMapper

//TODO: handle headers.

public class SpaceDogServices {
    
   public static func get<T: Mappable>(url: String, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        Alamofire.request(.GET, url).responseJSON { response in
        
            if let code = response.response?.statusCode where 200..<300 ~= code {
                let object = Mapper<T>().map(response.result.value)!
                successHandler(object)
            }
            else {
            
                var res: SDResponse!
                
                if let error = response.result.error {
                    let sdError = SDError(type: error.domain, message:error.localizedDescription)
                    res = SDResponse(success: false, status:error.code, error: sdError)
                }
                else {
                    res = Mapper<SDResponse>().map(response.result.value)
                }
                failureHandler(res)
            }
        }
    }

   public static func post<T: Mappable>(url: String, parameters: [String: AnyObject]?, headers: [String: String]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .JSON, headers: headers).responseJSON { response in
            
            if let code = response.response?.statusCode where 200..<300 ~= code {
                let object = Mapper<T>().map(response.result.value)!
                successHandler(object)
            }
            else {
                
                var res: SDResponse!
                
                if let error = response.result.error {
                    let sdError = SDError(type: error.domain, message:error.localizedDescription)
                    res = SDResponse(success: false, status:error.code, error: sdError)
                }
                else {
                    res = Mapper<SDResponse>().map(response.result.value)
                }
                failureHandler(res)
            }
        }
    }
    
    public static func put<T: Mappable>(url: String, parameters: [String: AnyObject]?, headers: [String: String]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        
        Alamofire.request(.PUT, url, parameters: parameters, encoding: .JSON, headers: headers).responseJSON { response in
            
            if let code = response.response?.statusCode where 200..<300 ~= code {
                let object = Mapper<T>().map(response.result.value)!
                successHandler(object)
            }
            else {
                
                var res: SDResponse!
                
                if let error = response.result.error {
                    let sdError = SDError(type: error.domain, message:error.localizedDescription)
                    res = SDResponse(success: false, status:error.code, error: sdError)
                }
                else {
                    res = Mapper<SDResponse>().map(response.result.value)
                }
                failureHandler(res)
            }
        }
    }
    
   public static func search<T: Mappable>(url: String, parameters: [String: AnyObject]?, successHandler: (SDSearch<T>) -> Void, failureHandler: (SDResponse) -> Void) {
        self.post(url, parameters: parameters, headers: nil, successHandler: successHandler, failureHandler: failureHandler)
    }
    
}
