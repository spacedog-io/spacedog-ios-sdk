//
//  SpaceDog.swift
//  SpaceDog-SDK-iOS
//
//  Created by philippe.rolland on 13/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation

import Foundation
import Alamofire
import ObjectMapper
import AlamofireObjectMapper

//TODO: handle headers.

public enum SDException: ErrorType {
    case Unauthorized
    case Forbidden
    case Unreachable(reason: String)
    case NotFound
    case ServerFailed
    case UnhandledHttpError(code: Int)
    case BadRequest
}

public class SpaceDog {
    
    let baseUrl: String
    let loginUrl: String
    let logoutUrl: String
    let dataUrl: String
    let searchUrl: String
    let installationUrl: String
    let pushUrl: String
    
    let context: SDContext
    
    public init(from: SDContext) {
        self.context = from
        self.baseUrl = "https://\(self.context.instanceId).spacedog.io"
        self.loginUrl = "\(self.baseUrl)/1/login"
        self.logoutUrl = "\(self.baseUrl)/1/logout"
        self.dataUrl = "\(self.baseUrl)/1/data"
        self.searchUrl = "\(self.baseUrl)/1/search"
        self.installationUrl = "\(self.baseUrl)/1/installation"
        self.pushUrl = "\(self.installationUrl)/push"
    }
    
    public convenience init(instanceId: String) {
        self.init(from: SDContext(instanceId: instanceId))
    }
    
    public func login(username username: String, password: String, success: ((SDCredentials) -> Void), error: ((SDException) -> Void)) {
        let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        
        request(method: Method.POST, url: self.loginUrl, auth: "Basic \(base64Credentials)",
            success: { (session: SDSession) in
                if let token = session.accessToken, expiresIn = session.expiresIn, credentialsId = session.credentialsId {
                    let credentials = SDCredentials(userId: credentialsId, userToken: token, expiresIn: expiresIn, acquired: NSDate())
                    self.context.setLogged(with: credentials)
                    print("Successfully logged in to SpaceDog: \(session.accessToken)")
                    success(credentials)
                } else {
                    error(SDException.Unauthorized)
                }
            },
            error: { (exception) in
                print("Error while logging to SpaceDog: \(exception)")
                error(exception)
            }
        )
    }
    
    public func logout(success success: ((Void) -> Void)? = nil, error: ((SDException) -> Void)? = nil) {
        request(method: Method.GET, url: self.logoutUrl, auth: self.bearer(),
            success: { (result: SDResponse) in
                self.context.setLoggedOut()
                print("Successfully logged out of SpaceDog \(result.success)")
                success?()
            },
            error: { (exception: SDException) in
                self.context.setLoggedOut()
                print("Error when trying to logout of SpaceDog: \(exception)")
                error?(exception)
            }
        )
    }
    
    public func get<T: Mappable>(entity entity: String, entityId: String, success: (T) -> Void, error: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)/\(entityId)"
        self.request(
            method: Method.GET,
            url: url,
            auth: self.bearer(),
            success: success,
            error: error)
    }
    
    public func create<T: Mappable>(entity entity: String, value: T, success: (String) -> Void, error: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)"
        self.request(
            method: Method.POST,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            success: {(r: SDResponse) in success(r.id!)},
            error: error)
    }
    
    public func update<T: Mappable>(entity entity: String, entityId: String, value: T, success: (Void) -> Void, error: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)/\(entityId)"
        self.request(
            method: Method.PUT,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            success: {(r: SDResponse) in success()},
            error: error)
    }
    
    public func update(entity entity: String, entityId: String, partial: [String : AnyObject], success: (Void) -> Void, error: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)/\(entityId)"
        self.request(
            method: Method.PUT,
            url: url,
            auth: self.bearer(),
            body: partial,
            success: {(r: SDResponse) in success()},
            error: error)
    }
    
    public func search<T: Mappable>(entity entity: String, query: [String: AnyObject], success: (SDSearch<T>) -> Void, error: (SDException) -> Void) {
        let url = "\(self.searchUrl)/\(entity)"
        self.request(
            method: Method.POST,
            url: url,
            auth: self.bearer(),
            body: query,
            success: success,
            error: error)
    }
    
    
    private func request<T: Mappable>(
        method method: Alamofire.Method,
        url: String,
        auth: String? = nil,
        body: [String: AnyObject]? = nil,
        success: (T) -> Void,
        error: (SDException) -> Void) {
        
        var headers = [String:String]()
        if let auth = auth {headers["Authorization"] = auth}
        var encoding = ParameterEncoding.URL
        if body != nil {encoding = ParameterEncoding.Custom(UTF8JSONEncoding())}
        
        Alamofire.request(method, url, parameters: body, encoding: encoding, headers: headers).responseJSON { response in
            self.handleResponse(response, success: success, error: error)
        }
        
    }
    
    private func bearer() -> String? {
        if let credentials = self.context.credentials {return "Bearer \(credentials.userToken)"}
        else {return nil}
    }
    
    
    typealias CustomEncoding = (URLRequestConvertible, [String:AnyObject]?) -> (NSMutableURLRequest, NSError?)
    
    private func UTF8JSONEncoding() -> CustomEncoding {
        let encoding: CustomEncoding = { URLRequest, parameters in
            
            let mutableURLRequest = URLRequest.URLRequest
            guard let parameters = parameters else { return (mutableURLRequest, nil) }
            
            var encodingError: NSError? = nil
            
            do {
                let options = NSJSONWritingOptions()
                let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: options)
                
                if mutableURLRequest.valueForHTTPHeaderField("Content-Type") == nil {
                    mutableURLRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                }
                
                mutableURLRequest.HTTPBody = data
            } catch {
                encodingError = error as NSError
            }
            
            return (mutableURLRequest, encodingError)
        }
        
        return encoding
    }
    
    public func installPushNotifications(deviceToken: String, appId: String, sandbox: Bool, success: () -> Void, error: (SDException) -> Void) {
        
        let parameters = ["token": deviceToken, "appId": appId, "pushService": sandbox == true ? "APNS_SANDBOX" : "APNS"]
        
        if let savedPushNotificationsId = retrievePushNotificationsId() {
            self.request(
                method: Method.PUT,
                url: "\(self.installationUrl)/\(savedPushNotificationsId)",
                body: parameters,
                success: {(r: SDResponse) in success()},
                error: error)
            
        } else {
            self.request(
                method: Method.POST,
                url: self.installationUrl,
                body: parameters,
                success: {(result: SDResponse) in
                    if let pushNotificationsId = result.id {
                        self.savePushNotificationsId(pushNotificationsId)
                    }
                    success()
                },
                error: error)
        }
    }
    
    private func savePushNotificationsId(id: String) {
        let ud = NSUserDefaults.standardUserDefaults()
        ud.setValue(id, forKey: "spacedog_push_notifications_id")
        ud.synchronize()
    }
    
    private func retrievePushNotificationsId() -> String? {
        let ud = NSUserDefaults.standardUserDefaults()
        return ud.valueForKey("spacedog_push_notifications_id") as? String
    }
    
    public func sendPushNotification(appId: String, message: [String: AnyObject], sandbox: Bool, success: (Void) -> Void, error: (SDException) -> Void) {
        
        let parameters: [String: AnyObject] = ["appId": appId, "message": message, "pushService": sandbox == true ? "APNS_SANDBOX" : "APNS"]
        
        self.request(
            method: Method.POST,
            url: self.pushUrl,
            auth: self.bearer(),
            body: parameters,
            success: {(result: SDResponse) in success()},
            error: error)
    }
    
    private func handleResponse<T: Mappable>(response: Response<AnyObject, NSError>, success: (T) -> Void, error: (SDException) -> Void) {
        self.debug(response)
        if let httpresponse = response.response {
            switch httpresponse.statusCode {
            case (200 ..< 300) :
                let object = Mapper<T>().map(response.result.value)!
                success(object)
            case 400 :
                error(SDException.BadRequest)
            case 401 :
                error(SDException.Unauthorized)
            case 403 :
                error(SDException.Forbidden)
            case 404 :
                error(SDException.NotFound)
            case 500 :
                error(SDException.ServerFailed)
            default:
                error(SDException.UnhandledHttpError(code: httpresponse.statusCode))
            }
        } else if let exception = response.result.error {
            error(SDException.Unreachable(reason: exception.localizedDescription))
        } else {
            error(SDException.Unreachable(reason: "Unknown response state"))
        }
    }
    
    private func debug(response: Response<AnyObject, NSError>) {
        if let method = response.request?.HTTPMethod, url = response.request?.URLString {
            if let httpResponse = response.response {
                print("\(method) \(url) \(httpResponse.statusCode)")
            } else {
                print("\(method) \(url) FAILED")
            }
            if let data = response.request?.HTTPBody, requestData = String(data: data, encoding: NSUTF8StringEncoding) {
                print("REQUEST:\n\(requestData)")
            }
            if let data = response.data, responseData = String(data: data, encoding: NSUTF8StringEncoding) {
                print("RESPONSE:\n\(responseData)")
            }
        }
    }
    
}

