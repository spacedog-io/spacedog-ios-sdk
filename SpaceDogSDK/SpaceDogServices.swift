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

public enum SDException: ErrorType {
    case Unauthorized
    case Forbidden
    case Unreachable(reason: String)
    case NotFound
    case ServerFailed
    case UnhandledHttpError(code: Int)
    case BadRequest
}

public class SpaceDogServices {
    
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
    
    public func login(username: String, password: String, successHandler: ((SDCredentials) -> Void), failureHandler: ((SDException) -> Void)) {
        let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        
        request(method: Method.POST, url: self.loginUrl, auth: "Basic \(base64Credentials)",
             successHandler: { (session: SDSession) in
                if let token = session.accessToken, expiresIn = session.expiresIn {
                    let credentials = SDCredentials(userId: username, userToken: token, expiresIn: expiresIn, acquired: NSDate())
                    self.context.setLogged(with: credentials)
                    print("Successfully logged in to SpaceDog: \(session.accessToken)")
                    successHandler(credentials)
                } else {
                    failureHandler(SDException.Unauthorized)
                }
            },
             failureHandler: { (exception) in
                print("Error while logging to SpaceDog: \(exception)")
                failureHandler(exception)
            }
        )
    }
    
    public func logout(successHandler: ((Void) -> Void)? = nil, failureHandler: ((SDException) -> Void)? = nil) {
        request(method: Method.GET, url: self.logoutUrl, auth: self.bearer(), successHandler: { (result: SDResponse) in
            print("Successfully logged out of SpaceDog \(result.success)")
            successHandler?()
        }, failureHandler: { (exception: SDException) in
            print("Error when trying to logout of SpaceDog: \(exception)")
            failureHandler?(exception)
        })
    }
    
    public func get<T: Mappable>(entity: String, entityId: String, successHandler: (T) -> Void, failureHandler: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)/\(entityId)"
        self.request(
            method: Method.GET,
            url: url,
            auth: self.bearer(),
            successHandler: successHandler,
            failureHandler: failureHandler)
    }
    
    public func create<T: Mappable>(entity: String, value: T, successHandler: (Void) -> Void, failureHandler: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)"
        self.request(
            method: Method.POST,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            successHandler: {(r: SDResponse) in successHandler()},
            failureHandler: failureHandler)
    }
    
    public func update<T: Mappable>(entity: String, entityId: String, value: T, successHandler: (Void) -> Void, failureHandler: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)/\(entityId)"
        self.request(
            method: Method.PUT,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            successHandler: {(r: SDResponse) in successHandler()},
            failureHandler: failureHandler)
    }
    
    public func search<T: Mappable>(entity: String, query: [String: AnyObject]?, successHandler: (SDSearch<T>) -> Void, failureHandler: (SDException) -> Void) {
        let url = "\(self.searchUrl)/\(entity)"
        self.request(
            method: Method.POST,
            url: url,
            auth: self.bearer(),
            body: query,
            successHandler: successHandler,
            failureHandler: failureHandler)
    }
    
    
    private func request<T: Mappable>(
        method method: Alamofire.Method,
        url: String,
        auth: String? = nil,
        body: [String: AnyObject]? = nil,
        successHandler: (T) -> Void,
        failureHandler: (SDException) -> Void) {
        
        var headers = [String:String]()
        if let auth = auth {headers["Authorization"] = auth}
        var encoding = ParameterEncoding.URL
        if body != nil {encoding = ParameterEncoding.Custom(UTF8JSONEncoding())}
        
        Alamofire.request(method, url, parameters: body, encoding: encoding, headers: headers).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
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
    
    /*
    public func get<T: Mappable>(urlPath: String, headers: [String: String]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        
        var theHeaders = [String:String]()
        if let inputHeaders = headers {
            theHeaders = inputHeaders
        }
        addBearerToHeaders(&theHeaders)
        
        let url = "https://\(appName).spacedog.io/\(urlPath)"
        
        Alamofire.request(.GET, url, headers: theHeaders).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
        }
    }

    
    public func post<T: Mappable>(urlPath: String, parameters: [String: AnyObject]?, headers: [String: String]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {
        
        var theHeaders = [String:String]()
        if let inputHeaders = headers {
            theHeaders = inputHeaders
        }
        addBearerToHeaders(&theHeaders)
        
        let url = "https://\(appName).spacedog.io/\(urlPath)"
        
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .Custom(UTF8JSONEncoding()), headers: theHeaders).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    public func put<T: Mappable>(urlPath: String, parameters: [String: AnyObject]?, headers: [String: String]?, successHandler: (T) -> Void, failureHandler: (SDResponse) -> Void) {

        
        var theHeaders = [String:String]()
        if let inputHeaders = headers {
            theHeaders = inputHeaders
        }
        addBearerToHeaders(&theHeaders)
        
        let url = "https://\(appName).spacedog.io/\(urlPath)"
        
        Alamofire.request(.PUT, url, parameters: parameters, encoding: .Custom(UTF8JSONEncoding()), headers: theHeaders).responseJSON { response in
            self.handleResponse(response, successHandler: successHandler, failureHandler: failureHandler)
        }
    }
    
    public func search<T: Mappable>(urlPath: String, parameters: [String: AnyObject]?, successHandler: (SDSearch<T>) -> Void, failureHandler: (SDResponse) -> Void) {
        
        post(urlPath, parameters: parameters, headers: nil, successHandler: successHandler, failureHandler: failureHandler)
    }
     */
    
    public func installPushNotifications(deviceToken: String, appId: String, sandbox: Bool, successHandler: (Void) -> Void, failureHandler: (SDException) -> Void) {
        
        let parameters = ["token": deviceToken, "appId": appId, "pushService": sandbox == true ? "APNS_SANDBOX" : "APNS"]
        
        if let savedPushNotificationsId = retrievePushNotificationsId() {
            self.request(
                method: Method.PUT,
                url: "\(self.installationUrl)/\(savedPushNotificationsId)",
                body: parameters,
                successHandler: {(r: SDResponse) in successHandler()},
                failureHandler: failureHandler)
            
        } else {
            self.request(
                method: Method.POST,
                url: self.installationUrl,
                body: parameters,
                successHandler: {(result: SDResponse) in
                    if let pushNotificationsId = result.id {
                        self.savePushNotificationsId(pushNotificationsId)
                    }
                    successHandler()
                },
                failureHandler: failureHandler)
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
    
    public func sendPushNotification(appId: String, message: [String: AnyObject], sandbox: Bool, successHandler: (Void) -> Void, failureHandler: (SDException) -> Void) {
        
        let parameters: [String: AnyObject] = ["appId": appId, "message": message, "pushService": sandbox == true ? "APNS_SANDBOX" : "APNS"]
        
        self.request(
            method: Method.POST,
            url: self.pushUrl,
            body: parameters,
            successHandler: {(result: SDResponse) in successHandler()},
            failureHandler: failureHandler)
    }
    
    private func handleResponse<T: Mappable>(response: Response<AnyObject, NSError>, successHandler: (T) -> Void, failureHandler: (SDException) -> Void) {
        if let httpresponse = response.response {
            switch httpresponse.statusCode {
            case (200 ..< 300) :
                let object = Mapper<T>().map(response.result.value)!
                    
                if let responseData = String(data: response.data!, encoding: NSUTF8StringEncoding) {
                    print("---- WS SUCCESS ----")
                    print("RESPONSE: \(responseData)")
                    print("REQUEST HEADER: \(response.request?.HTTPMethod) \(response.request?.URLString)")
                    
                    if let requestBodyData = response.request?.HTTPBody {
                        do {
                            let requestJSONBody = try NSJSONSerialization.JSONObjectWithData(requestBodyData, options: .AllowFragments)
                            
                            print("REQUEST BODY: \(response.request?.HTTPMethod) \(response.request?.URLString) with data: \(requestJSONBody)")
                        } catch {}
                    }
                    print("---- END -----")
                }
                successHandler(object)
            case 400 :
                failureHandler(SDException.BadRequest)
            case 401 :
                failureHandler(SDException.Unauthorized)
            case 403 :
                failureHandler(SDException.Forbidden)
            case 404 :
                failureHandler(SDException.NotFound)
            case 500 :
                failureHandler(SDException.ServerFailed)
            default:
                failureHandler(SDException.UnhandledHttpError(code: httpresponse.statusCode))
            }
        } else if let error = response.result.error {
            failureHandler(SDException.Unreachable(reason: error.localizedDescription))
        } else {
            failureHandler(SDException.Unreachable(reason: "Unknown response state"))
        }
    }
    
}
