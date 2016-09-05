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
    private let APP_NAME_MANDATORY_ERROR = "ERROR: appName property is mandatory"
    
    static let sharedInstance = SpaceDogServices()
    
    var appName : String?
    
    init() {
    }
    
    public func get<T: Mappable>(urlPath: String, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        guard appName != nil else {
            print(APP_NAME_MANDATORY_ERROR)
            return
        }
        
        let url = "https://\(appName!).spacedog.io/\(urlPath)"
        
        Alamofire.request(.GET, url).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    public func post<T: Mappable>(urlPath: String, parameters: [String: AnyObject]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        guard appName != nil else {
            print(APP_NAME_MANDATORY_ERROR)
            return
        }
        
        let url = "https://\(appName!).spacedog.io/\(urlPath)"
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .JSON).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    public func put<T: Mappable>(urlPath: String, parameters: [String: AnyObject]?, headers: [String: String]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        guard appName != nil else {
            print(APP_NAME_MANDATORY_ERROR)
            return
        }
        
        let url = "https://\(appName!).spacedog.io/\(urlPath)"
        
        Alamofire.request(.PUT, url, parameters: parameters, encoding: .JSON, headers: headers).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    public func search<T: Mappable>(urlPath: String, parameters: [String: AnyObject]?, successHandler: (SDSearch<T>) -> Void, failureHandler: (SDResponse) -> Void) {
        guard appName != nil else {
            print(APP_NAME_MANDATORY_ERROR)
            return
        }
        
        post(urlPath, parameters: parameters, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func installPushNotifications(deviceToken: String, appId: String, sandbox: Bool, successHandler: (Void) -> Void, failureHandler: (Void) -> Void) {
        guard appName != nil else {
            print(APP_NAME_MANDATORY_ERROR)
            return
        }
        
        let parameters = ["token": deviceToken, "appId": appId, "pushService": sandbox == true ? "APNS_SANDBOX" : "APNS"]
        
        post("1/installation", parameters: parameters,
             successHandler: { (result: SDResponse) in
                print("Successfully subscribed to SpaceDog Push Notifications service: \(result)")
                successHandler()
            },
             failureHandler: { (errorResponse) in
                print("Error while subscribing to SpaceDog Push Notifications service: \(errorResponse.error?.message)")
                failureHandler()
            }
        )
    }
    
    private func handleResponse<T: Mappable>(response: Response<AnyObject, NSError>, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
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
