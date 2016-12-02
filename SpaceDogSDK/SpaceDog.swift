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
import PromiseKit

//TODO: handle headers.

public enum SDException: ErrorType {
    case Unauthorized
    case Forbidden
    case Unreachable(reason: String)
    case NotFound
    case ServerFailed
    case UnhandledHttpError(code: Int)
    case BadRequest
    case DeviceNotReadyForInstallation
}

public class SpaceDog {
    
    let baseUrl: String
    let loginUrl: String
    let logoutUrl: String
    let credentialsUrl: String
    let dataUrl: String
    let searchUrl: String
    let installationUrl: String
    let pushUrl: String
    let stripeUrl: String
    
    let context: SDContext
    
    
    public init(instanceId: String, appId: String) {
        self.baseUrl = "https://\(instanceId).spacedog.io"
        self.loginUrl = "\(self.baseUrl)/1/login"
        self.logoutUrl = "\(self.baseUrl)/1/logout"
        self.credentialsUrl = "\(self.baseUrl)/1/credentials"
        self.dataUrl = "\(self.baseUrl)/1/data"
        self.searchUrl = "\(self.baseUrl)/1/search"
        self.installationUrl = "\(self.baseUrl)/1/installation"
        self.pushUrl = "\(self.installationUrl)/push"
        self.stripeUrl = "\(self.baseUrl)/1/stripe/customers"
        
        self.context = SDContext(instanceId: instanceId, appId: appId)
        
        let ud = NSUserDefaults.standardUserDefaults()
        if let savedInstanceId = ud.stringForKey(SDContext.InstanceId) {
            if savedInstanceId == instanceId {
                let expiresIn = ud.integerForKey(SDContext.ExpiresIn);
                let issuedOn = ud.doubleForKey(SDContext.IssuedOn);
                if expiresIn > 0 && issuedOn > 0,
                    let accessToken = ud.stringForKey(SDContext.AccessToken),
                    let credentialsId = ud.stringForKey(SDContext.CredentialsId),
                    let credentialsEmail = ud.stringForKey(SDContext.CredentialsEmail) {
                    
                    let date = NSDate(timeIntervalSinceReferenceDate: issuedOn)
                    let credentials = SDCredentials(userId: credentialsId, userToken: accessToken, userEmail: credentialsEmail, expiresIn: expiresIn, acquired: date)
                    context.setLogged(with: credentials)
                }
                if let deviceId = ud.stringForKey(SDContext.DeviceId) {
                    context.deviceId = deviceId
                }
                if let installationId = ud.stringForKey(SDContext.InstallationId) {
                    context.installationId = installationId
                }
            }
        }
        self.saveContext()
        print("[SpaceDog] initialized with context \(self.context)")
    }
    
    private func saveContext() {
        let ud = NSUserDefaults.standardUserDefaults()
        ud.setObject(self.context.instanceId, forKey: SDContext.InstanceId)
        if let credentials = self.context.credentials {
            ud.setObject(credentials.userToken, forKey: SDContext.AccessToken)
            ud.setObject(credentials.userId, forKey: SDContext.CredentialsId)
            ud.setObject(credentials.userEmail, forKey: SDContext.CredentialsEmail)
            ud.setObject(credentials.expiresIn, forKey: SDContext.ExpiresIn)
            ud.setObject(credentials.acquired.timeIntervalSinceReferenceDate, forKey: SDContext.IssuedOn)
        } else {
            ud.removeObjectForKey(SDContext.AccessToken)
            ud.removeObjectForKey(SDContext.CredentialsId)
            ud.removeObjectForKey(SDContext.CredentialsEmail)
            ud.removeObjectForKey(SDContext.ExpiresIn)
            ud.removeObjectForKey(SDContext.IssuedOn)
        }
        if let installationId = self.context.installationId {
            ud.setObject(installationId, forKey: SDContext.InstallationId)
        } else {
            ud.removeObjectForKey(SDContext.InstallationId)
        }
        if let deviceId = self.context.deviceId {
            ud.setObject(deviceId, forKey: SDContext.DeviceId)
        } else {
            ud.removeObjectForKey(SDContext.DeviceId)
        }
    }
    
    private func convertToBase64(username: String, password: String) -> String {
        let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        return base64Credentials
    }
    
    //MARK: Log in / Log out
    public func login(username username: String, password: String, success: ((SDCredentials) -> Void), error: ((SDException) -> Void)) {
        let base64Credentials = self.convertToBase64(username, password: password)
        
        request(
            method: Method.POST,
            url: self.loginUrl,
            auth: "Basic \(base64Credentials)",
            success: { (session: SDSession) in
                if let token = session.accessToken, expiresIn = session.expiresIn,
                    credentialsId = session.credentialsId, credentialsEmail = session.credentialsEmail {
                    let credentials = SDCredentials(userId: credentialsId, userToken: token,
                        userEmail: credentialsEmail, expiresIn: expiresIn, acquired: NSDate())
                    self.context.setLogged(with: credentials)
                    self.saveContext()
                    print("Successfully logged in to SpaceDog: \(session.accessToken)")
                    self.install(
                        forDevice: self.context.deviceId,
                        success: { () in
                            success(credentials)
                        },
                        error: error
                    )
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
        request(
            method: Method.GET,
            url: self.logoutUrl,
            auth: self.bearer(),
            success: { (result: SDResponse) in
                self.context.setLoggedOut()
                self.install(forDevice: self.context.deviceId, success: {}, error: {_ in})
                self.saveContext()
                print("Successfully logged out of SpaceDog \(result.success)")
                success?()
            },
            error: { (exception: SDException) in
                self.context.setLoggedOut()
                self.install(forDevice: self.context.deviceId, success: {}, error: {_ in})
                self.saveContext()
                print("Error when trying to logout of SpaceDog: \(exception)")
                error?(exception)
            }
        )
    }
    
    //MARK: Credentials
    public func createCredentials(email: String, username: String, password: String, success: ((String) -> Void), error: ((SDException) -> Void)) {
        
        let parameters: [String:String] = ["email": email, "username": username, "password": password]
        
        request(
            method: Method.POST,
            url: self.credentialsUrl,
            body: parameters,
            success: { ( result: SDResponse) in
                if let credentialsId = result.id {
                    print("Successfully created credentials in Spacedog: \(credentialsId)")
                    success(credentialsId)
                } else {
                    error(SDException.Unauthorized)
                }
            },
            error: { (exception) in
                print("Error while creating crendentials to SpaceDog: \(exception)")
                error(exception)
            }
        )
    }
    
    public func updateCredentials(credentialsId: String, username: String, password: String, parameters: [String:String],
                                  success: ((Void) -> Void), error: ((SDException) -> Void)) {
        
        let base64Credentials = self.convertToBase64(username, password: password)

        request(method: Method.PUT, url: self.credentialsUrl+"/"+credentialsId, auth: "Basic \(base64Credentials)",
                body: parameters,
                success: { ( result: SDResponse) in
                    if result.success == true {
                        print("Successfully updated credentials in Spacedog")
                        success()
                    }
                    else {
                        error(SDException.Unauthorized)
                    }
            },
                error: { (exception) in
                    print("Error while updating crendentials to SpaceDog: \(exception)")
                    error(exception)
            }
        )
    }
    
    
    //MARK: Stripe

    public func getMyStripeCustomer() -> Promise<StripeCustomer> {
        return Promise { fufill, reject in
            request(method: Method.GET, url: "\(self.stripeUrl)/me", auth: self.bearer(),
                success: { (stripeCustomer: StripeCustomer) in
                    fufill(stripeCustomer)
            }, error: { (error: SDException) in
                    reject(error)
            })
        }
    }
    
    public func createStripeCustomer() -> Promise<StripeCustomer> {
        return Promise { fufill, reject in
            request(method: Method.POST, url: self.stripeUrl, auth: self.bearer(),
                success: {(stripeCustomer: StripeCustomer) in
                    fufill(stripeCustomer)
                }, error: { (error) in
                    reject(error)
            })
        }
    }

    
    public func createCard(cardToken token: String, cardLabel: String) -> Promise<Card> {
        return Promise { fufill, reject in
            request(method: Method.POST, url: "\(self.stripeUrl)/me/sources", auth: self.bearer(),
                body: ["source": token, "description": cardLabel],
                success: { (card: Card) in
                    fufill(card)
                }, error: { (error) in
                    reject(error)
            })
        }
    }

    
    public func deleteCard(cardId id: String) -> Promise<String> {
        return Promise { fufill, reject in
            request(method: Method.DELETE, url: "\(self.stripeUrl)/me/sources/\(id)", auth: self.bearer(),
                success: { (card: Card) in
                    fufill(card.id ?? "")
                }, error:{ (error) in
                    reject(error)
            })
        }
    }
    
    //MARK: SpaceDog Entities
    
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
    
    public func update<T: Mappable>(entity entity: String, entityId: String, value: T, strictVersioning version: Int? = nil, success: (Void) -> Void, error: (SDException) -> Void) {
        var url = "\(self.dataUrl)/\(entity)/\(entityId)"
        
        if let version = version { url += "?version=\(version)"}
        self.request(
            method: Method.PUT,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            success: {(r: SDResponse) in success()},
            error: error)
    }
    
    public func update(entity entity: String, entityId: String, partial: [String : AnyObject], strictVersioning version: Int? = nil, success: (Void) -> Void, error: (SDException) -> Void) {
        var url = "\(self.dataUrl)/\(entity)/\(entityId)"
        
        if let version = version { url += "?version=\(version)"}
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
    
    public func install(forDevice deviceId: String?, success: () -> Void, error: (SDException) -> Void) {
        if deviceId == nil && self.context.installationId == nil {
            error(SDException.DeviceNotReadyForInstallation)
        } else {
            var parameters: [String:AnyObject] = ["appId": self.context.appId]
            if let token = deviceId {
                parameters["token"] = token
                self.context.deviceId = token
                self.saveContext()
            }
            #if DEBUG
                parameters["pushService"] = "APNS_SANDBOX"
            #else
                parameters["pushService"] = "APNS"
            #endif
            
            if let credential = self.context.credentials {
                parameters["tags"] = [["key":"credentialsId", "value":credential.userId]]
            } else {
                parameters["tags"] = []
            }
            
            if let installationId = self.context.installationId {
                self.request(
                    method: Method.PUT,
                    url: "\(self.installationUrl)/\(installationId)",
                    body: parameters,
                    success: {(r: SDResponse) in success()},
                    error: {sderror in
                        switch (sderror) {
                        case SDException.NotFound:
                            self.context.installationId = nil
                            self.saveContext()
                            self.install(forDevice: deviceId, success: success, error: error)
                        default:
                            error(sderror)
                        }
                    }
                )
            } else {
                self.request(
                    method: Method.POST,
                    url: self.installationUrl,
                    body: parameters,
                    success: {(result: SDResponse) in
                        if let iid = result.id {
                            self.context.installationId = iid
                            self.saveContext()
                            success()
                        } else {
                            error(SDException.DeviceNotReadyForInstallation)
                        }
                    },
                    error: error)
            }
        }
    }
    
    public func sendPushNotification(appId: String, message: [String: AnyObject], credentialsId: String, success: (Void) -> Void, error: (SDException) -> Void) {
        
        let tags = [["key":"credentialsId", "value": credentialsId]]
        #if DEBUG
            let body: [String: AnyObject] = ["appId": appId, "message": ["APNS_SANDBOX": message], "pushService": "APNS_SANDBOX", "tags": tags]
        #else
            let body: [String: AnyObject] = ["appId": appId, "message": ["APNS": message], "pushService": "APNS", "tags": tags]
        #endif
        
        //let parameters: [String: AnyObject] = ["appId": appId, "message": message, "pushService": sandbox == true ? "APNS_SANDBOX" : "APNS"]
        
        self.request(
            method: Method.POST,
            url: self.pushUrl,
            auth: self.bearer(),
            body: body,
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

