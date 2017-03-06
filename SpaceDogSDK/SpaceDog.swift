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

public enum UnauthorizedCode: String {
    case invalidCredentials = "invalid-credentials",
    expiredAccessToken = "expired-access-token",
    invalidAccessToken = "invalid-access-token",
    disabledCredentials = "disabled-credentials",
    invalidAuthorizationHeader = "invalid-authorization-header"
}

public enum BadRequestCode: String {
    case alreadyExists = "already-exists",
    unhandledErrorCode
}

public enum SDException: Error {
    case unauthorized(code: UnauthorizedCode)
    case forbidden
    case unreachable(reason: String)
    case notFound
    case serverFailed
    case unhandledHttpError(code: Int)
    case badRequest(code: BadRequestCode)
    case deviceNotReadyForInstallation
}

open class SpaceDog {
    
    let baseUrl: String
    let loginUrl: String
    let logoutUrl: String
    let credentialsUrl: String
    let dataUrl: String
    let searchUrl: String
    let batchUrl: String
    let installationUrl: String
    let pushUrl: String
    let stripeUrl: String
    let settingsUrl: String
    let smsUrl: String
    let mailUrl: String
    
    let context: SDContext
    let manager: Alamofire.SessionManager
    
    public init(instanceId: String, appId: String) {
        self.baseUrl = "https://\(instanceId).spacedog.io"
        self.loginUrl = "\(self.baseUrl)/1/login"
        self.logoutUrl = "\(self.baseUrl)/1/logout"
        self.credentialsUrl = "\(self.baseUrl)/1/credentials"
        self.dataUrl = "\(self.baseUrl)/1/data"
        self.searchUrl = "\(self.baseUrl)/1/search"
        self.batchUrl = "\(self.baseUrl)/1/batch"
        self.installationUrl = "\(self.baseUrl)/1/installation"
        self.pushUrl = "\(self.installationUrl)/push"
        self.stripeUrl = "\(self.baseUrl)/1/stripe/customers"
        self.settingsUrl = "\(self.baseUrl)/1/settings"
        self.smsUrl = "\(self.baseUrl)/1/sms/template"
        self.mailUrl = "\(self.baseUrl)/1/mail/template"

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 60
        self.manager = Alamofire.SessionManager(configuration: configuration)
        
        self.context = SDContext(instanceId: instanceId, appId: appId)
        
        let ud = UserDefaults.standard
        if let savedInstanceId = ud.string(forKey: SDContext.InstanceId) {
            if savedInstanceId == instanceId {
                let expiresIn = ud.integer(forKey: SDContext.ExpiresIn);
                let issuedOn = ud.double(forKey: SDContext.IssuedOn);
                if expiresIn > 0 && issuedOn > 0,
                    let accessToken = ud.string(forKey: SDContext.AccessToken),
                    let credentialsId = ud.string(forKey: SDContext.CredentialsId),
                    let credentialsEmail = ud.string(forKey: SDContext.CredentialsEmail) {
                    
                    let date = Date(timeIntervalSinceReferenceDate: issuedOn)
                    let credentials = SDCredentials(userId: credentialsId, userToken: accessToken, userEmail: credentialsEmail, expiresIn: expiresIn, acquired: date)
                    context.setLogged(with: credentials)
                }
                if let deviceId = ud.string(forKey: SDContext.DeviceId) {
                    context.deviceId = deviceId
                }
                if let installationId = ud.string(forKey: SDContext.InstallationId) {
                    context.installationId = installationId
                }
            }
        }
        self.saveContext()
        print("[SpaceDog] initialized with context \(self.context)")
    }
    
    fileprivate func saveContext() {
        let ud = UserDefaults.standard
        ud.set(self.context.instanceId, forKey: SDContext.InstanceId)
        if let credentials = self.context.credentials {
            ud.set(credentials.userToken, forKey: SDContext.AccessToken)
            ud.set(credentials.userId, forKey: SDContext.CredentialsId)
            ud.set(credentials.userEmail, forKey: SDContext.CredentialsEmail)
            ud.set(credentials.expiresIn, forKey: SDContext.ExpiresIn)
            ud.set(credentials.acquired.timeIntervalSinceReferenceDate, forKey: SDContext.IssuedOn)
        } else {
            ud.removeObject(forKey: SDContext.AccessToken)
            ud.removeObject(forKey: SDContext.CredentialsId)
            ud.removeObject(forKey: SDContext.CredentialsEmail)
            ud.removeObject(forKey: SDContext.ExpiresIn)
            ud.removeObject(forKey: SDContext.IssuedOn)
        }
        if let installationId = self.context.installationId {
            ud.set(installationId, forKey: SDContext.InstallationId)
        } else {
            ud.removeObject(forKey: SDContext.InstallationId)
        }
        if let deviceId = self.context.deviceId {
            ud.set(deviceId, forKey: SDContext.DeviceId)
        } else {
            ud.removeObject(forKey: SDContext.DeviceId)
        }
    }
    
    fileprivate func convertToBase64(_ username: String, password: String) -> String {
        let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return base64Credentials
    }
    
    //MARK: Log in / Log out
    open func login(username: String, password: String, success: @escaping ((SDCredentials) -> Void), error: @escaping ((SDException) -> Void)) {
        let base64Credentials = self.convertToBase64(username, password: password)
        
        request(
            method: .post,
            url: self.loginUrl,
            auth: "Basic \(base64Credentials)",
            success: { (session: SDSession) in
                if let token = session.accessToken, let expiresIn = session.expiresIn,
                    let credentialsId = session.credentialsId, let credentialsEmail = session.credentialsEmail {
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
                    error(SDException.Unauthorized(code: UnauthorizedCode.invalidAccessToken))
                }
            },
            error: { (exception) in
                print("Error while logging to SpaceDog: \(exception)")
                error(exception)
            }
        )
    }
    
    open func logout(success: ((Void) -> Void)? = nil, error: ((SDException) -> Void)? = nil) {
        request(
            method: .get,
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
    open func createCredentials(_ email: String, username: String, password: String, success: @escaping ((String) -> Void), error: @escaping ((SDException) -> Void)) {
        
        let parameters: [String:String] = ["email": email, "username": username, "password": password]
        
        request(
            method: .post,
            url: self.credentialsUrl,
            body: parameters,
            success: { ( result: SDResponse) in
                if let credentialsId = result.id {
                    print("Successfully created credentials in Spacedog: \(credentialsId)")
                    success(credentialsId)
                } else {
                    let code = UnauthorizedCode(rawValue: result.error?.code ?? "") ?? UnauthorizedCode.expiredAccessToken
                    error(SDException.Unauthorized(code: code))
                }
            },
            error: { (exception) in
                print("Error while creating crendentials to SpaceDog: \(exception)")
                error(exception)
            }
        )
    }
    
    open func updateCredentials(_ credentialsId: String, username: String, password: String, parameters: [String:String],
                                  success: @escaping ((Void) -> Void), error: @escaping ((SDException) -> Void)) {
        
        let base64Credentials = self.convertToBase64(username, password: password)

        request(method: .put, url: self.credentialsUrl+"/"+credentialsId, auth: "Basic \(base64Credentials)",
                body: parameters,
                success: { ( result: SDResponse) in
                    if result.success == true {
                        print("Successfully updated credentials in Spacedog")
                        success()
                    }
                    else {
                        error(SDException.Unauthorized(code: UnauthorizedCode(rawValue: result.error!.code!)!))
                    }
            },
                error: { (exception) in
                    print("Error while updating crendentials to SpaceDog: \(exception)")
                    error(exception)
            }
        )
    }
    
    //MARK: Settings
    
    open func getSettings<T: Mappable>(_ settingsName: String) -> Promise<T> {
        return Promise { fufill, reject in
            request(method: .get, url: "\(self.settingsUrl)/\(settingsName)", auth: self.bearer(),
                success: { (settings: T) in
                    fufill(settings)
                }, error: { (error: SDException) in
                    reject(error)
            })
        }
    }
    
    
    //MARK: SMS
    
    open func sendSMS(_ templateName: String, parameters: [String: Any]) -> Promise<SDResponse> {
        return Promise { fufill, reject in
            request(method: .post, url: "\(self.smsUrl)/\(templateName)", body: parameters, auth: self.bearer(),
                success: { (response: SDResponse) in
                    fufill(response)
                }, error: { (error: SDException) in
                    reject(error)
            })
        }
    }
    
    //MARK: Mail

    open func sendMail(_ templateName: String, parameters: [String: Any]) -> Promise<SDResponse> {
        return Promise { fufill, reject in
            request(method: .post, url: "\(self.mailUrl)/\(templateName)", body: parameters, auth: self.bearer(),
                success: { (response: SDResponse) in
                    fufill(response)
                }, error: { (error: SDException) in
                    reject(error)
            })
        }
    }
    
    //MARK: Stripe

    open func getMyStripeCustomer() -> Promise<StripeCustomer> {
        return Promise { fufill, reject in
            request(method: .get, url: "\(self.stripeUrl)/me", auth: self.bearer(),
                success: { (stripeCustomer: StripeCustomer) in
                    fufill(stripeCustomer)
            }, error: { (error: SDException) in
                    reject(error)
            })
        }
    }
    
    open func createStripeCustomer() -> Promise<StripeCustomer> {
        return Promise { fufill, reject in
            request(method: .post, url: self.stripeUrl, auth: self.bearer(),
                success: {(stripeCustomer: StripeCustomer) in
                    fufill(stripeCustomer)
                }, error: { (error) in
                    reject(error)
            })
        }
    }

    
    open func createCard(cardToken token: String, cardLabel: String) -> Promise<Card> {
        return Promise { fufill, reject in
            request(method: .post, url: "\(self.stripeUrl)/me/sources", auth: self.bearer(),
                body: ["source": token, "description": cardLabel],
                success: { (card: Card) in
                    fufill(card)
                }, error: { (error) in
                    reject(error)
            })
        }
    }

    
    open func deleteCard(cardId id: String) -> Promise<String> {
        return Promise { fufill, reject in
            request(method: .delete, url: "\(self.stripeUrl)/me/sources/\(id)", auth: self.bearer(),
                success: { (card: Card) in
                    fufill(card.id ?? "")
                }, error:{ (error) in
                    reject(error)
            })
        }
    }
    
    //MARK: SpaceDog Entities
    
    open func get<T: Mappable>(entity: String, entityId: String, success: @escaping (T) -> Void, error: @escaping (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)/\(entityId)"
        self.request(
            method: .get,
            url: url,
            auth: self.bearer(),
            success: success,
            error: error)
    }
    
    open func create<T: Mappable>(entity: String, value: T, success: (SDResponse) -> Void, error: (SDException) -> Void) {
        let url = "\(self.dataUrl)/\(entity)"
        self.request(
            method: .post,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            success: success,
            error: error)
    }
    
    open func update<T: Mappable>(entity: String, entityId: String, value: T, strictVersioning version: Int? = nil, success: (SDResponse) -> Void, error: (SDException) -> Void) {
        var url = "\(self.dataUrl)/\(entity)/\(entityId)"
        
        if let version = version { url += "?version=\(version)"}
        self.request(
            method: .put,
            url: url,
            auth: self.bearer(),
            body: value.toJSON(),
            success: success,
            error: error)
    }
    
    open func update(entity: String, entityId: String, partial: [String : Any], strictVersioning version: Int? = nil, success: (SDResponse) -> Void, error: (SDException) -> Void) {
        var url = "\(self.dataUrl)/\(entity)/\(entityId)"
        
        if let version = version { url += "?version=\(version)"}
        self.request(
            method: .put,
            url: url,
            auth: self.bearer(),
            body: partial,
            success: success,
            error: error)
    }
    
    open func search<T: Mappable>(entity: String, query: [String: Any], success: (SDSearch<T>) -> Void, error: (SDException) -> Void) {
        let url = "\(self.searchUrl)/\(entity)"
        self.request(
            method: .post,
            url: url,
            auth: self.bearer(),
            body: query,
            success: success,
            error: error)
    }
    
    open func batch(_ queries: [[String: Any]], success: (SDBatch) -> Void, error: (SDException) -> Void) {
        let url = self.batchUrl
        self.request(
            method: .post,
            url: url,
            auth: self.bearer(),
            body: queries,
            success: success,
            error: error)
    }
    
    fileprivate func request<T: Mappable>(
        method: HTTPMethod,
        url: String,
        auth: String? = nil,
        body: [String: Any]? = nil,
        success: @escaping (T) -> Void,
        error: @escaping (SDException) -> Void) {
        
        var headers = [String:String]()
        if let auth = auth {headers["Authorization"] = auth}
        var encoding = ParameterEncoding.URL
        if body != nil {encoding = ParameterEncoding.Custom(UTF8JSONEncoding())}
        
        manager.request(method, url, parameters: body, encoding: encoding, headers: headers).responseJSON { response in
            self.handleResponse(response, success: success, error: error)
        }
        
    }

    fileprivate func request<T: Mappable>(
        method: Alamofire.Method,
               url: String,
               auth: String? = nil,
               body: [[String: Any]],
               success: @escaping (T) -> Void,
               error: @escaping (SDException) -> Void) {
        
        var headers = [String:String]()
        if let auth = auth {headers["Authorization"] = auth}
        let encoding = ParameterEncoding.Custom(UTF8JSONEncoding(WithArray: true))
        
        manager.request(method, url, parameters: ["array": body], encoding: encoding, headers: headers).responseJSON { response in
            self.handleResponse(response, success: success, error: error)
        }
    }

    fileprivate func bearer() -> String? {
        if let credentials = self.context.credentials {return "Bearer \(credentials.userToken)"}
        else {return nil}
    }
    

    //MARK: Encoding
    
    typealias CustomEncoding = (URLRequestConvertible, [String:Any]?) -> (NSMutableURLRequest, NSError?)
    
    fileprivate func UTF8JSONEncoding(WithArray isArray: Bool = false) -> CustomEncoding {
        let encoding: CustomEncoding = { URLRequest, parameters in
            
            let mutableURLRequest = URLRequest.URLRequest
            
            var params: Any

            if let parameters = parameters?.first?.1, isArray == true {
                params = parameters
            }
            else if let parameters = parameters, isArray == false {
                params = parameters
            }
            else {
                return (mutableURLRequest, nil)
            }
            
            var encodingError: NSError? = nil
            
            do {
                let options = NSJSONWritingOptions()
                let data = try NSJSONSerialization.dataWithJSONObject(params, options: options)
                
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
    
    //MARK: Push notifications
    
    open func install(forDevice deviceId: String?, success: @escaping () -> Void, error: @escaping (SDException) -> Void) {
        if deviceId == nil && self.context.installationId == nil {
            success()
            //error(SDException.DeviceNotReadyForInstallation)
        } else {
            var parameters: [String:Any] = ["appId": self.context.appId as Any]
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
                
                self.getInstallation(installationId).then({ (installation: SDInstallation) -> Void in
                    
                    if let itags = installation.tags {
                        let extraTags = itags.flatMap({ (tag: SDTag) -> [String: Any]? in
                            return tag.key != "credentialsId" ? tag.toJSON() : nil
                        })
                        var tags = parameters["tags"] as! [[String: Any]]
                        tags += extraTags
                        parameters["tags"] = tags
                    }
                    
                    self.request(
                        method: .put,
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
                }).error({ (sderror) in
                    switch (sderror) {
                    case SDException.NotFound:
                        self.context.installationId = nil
                        self.saveContext()
                        self.install(forDevice: deviceId, success: success, error: error)
                    default:
                        error(SDException.DeviceNotReadyForInstallation)
                    }
                })
        
            } else {
                self.request(
                    method: .post,
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
    
    open func sendPushNotification(_ appId: String, message: [String: Any], tags: [[String:String]], success: @escaping (Void) -> Void, error: (SDException) -> Void) {
        
        #if DEBUG
            let body: [String: Any] = ["appId": appId, "message": ["APNS_SANDBOX": message], "pushService": "APNS_SANDBOX", "tags": tags]
        #else
            let body: [String: Any] = ["appId": appId as Any, "message": ["APNS": message], "pushService": "APNS", "tags": tags]
        #endif
        
        self.request(
            method: .post,
            url: self.pushUrl,
            auth: self.bearer(),
            body: body,
            success: {(result: SDResponse) in success()},
            error: error)
    }
    

    open func createTag(_ installationId: String, key: String, value: String) -> Promise<SDResponse> {
        return Promise { fufill, reject in
            self.request(
                method: .post,
                url: "\(self.installationUrl)/\(installationId)/tags",
                body: ["key": key, "value": value],
                success: {(r: SDResponse) in
                    fufill(r)
                },
                error: reject)
        }
    }

    
    open func updateTags(_ installationId: String, parameters: [[String: Any]]) -> Promise<SDResponse> {
        return Promise { fufill, reject in
            self.request(
                method: .put,
                url: "\(self.installationUrl)/\(installationId)/tags",
                body: parameters,
                success: {(r: SDResponse) in
                    fufill(r)
                },
                error: reject)
        }
    }
    
    open func deleteTag(_ installationId: String, key: String, value: String) -> Promise<SDResponse> {
        return Promise { fufill, reject in
            self.request(
                method: .delete,
                url: "\(self.installationUrl)/\(installationId)/tags",
                body: ["key": key, "value": value],
                success: {(r: SDResponse) in
                    fufill(r)
                },
                error: reject)
        }
    }
    
    
    open func getInstallation(_ installationId: String) -> Promise<SDInstallation> {
        return Promise { fufill, reject in
            request(method: .get, url: "\(self.installationUrl)/\(installationId)",
                success: { (installation: SDInstallation) in
                    fufill(installation)
                }, error: reject)
        }
    }
    
    
    fileprivate func handleResponse<T: Mappable>(_ response: DataResponse<Any>, success: (T) -> Void, error: (SDException) -> Void) {
        self.debug(response)
        if let httpresponse = response.response {
            switch httpresponse.statusCode {
            case (200 ..< 300) :
                let object = Mapper<T>().map(response.result.value)!
                success(object)
            case 400 :
                if let res = Mapper<SDResponse>().map(response.result.value),
                    let code = res.error?.code,
                    let badRequestCode = BadRequestCode(rawValue: code) {
                    error(SDException.BadRequest(code: badRequestCode))
                }
                else {
                    error(SDException.badRequest(code: BadRequestCode.unhandledErrorCode))
                }
            case 401 :
                if let res = Mapper<SDResponse>().map(response.result.value),
                    let code = res.error?.code,
                    let unauthorizedCode = UnauthorizedCode(rawValue: code) {
                        error(SDException.Unauthorized(code: unauthorizedCode))
                }
                else {
                    error(SDException.unauthorized(code: UnauthorizedCode.invalidAccessToken))
                }
            case 403 :
                error(SDException.forbidden)
            case 404 :
                error(SDException.notFound)
            case 500 :
                error(SDException.serverFailed)
            default:
                error(SDException.UnhandledHttpError(code: httpresponse.statusCode))
            }
        } else if let exception = response.result.error {
            error(SDException.Unreachable(reason: exception.localizedDescription))
        } else {
            error(SDException.unreachable(reason: "Unknown response state"))
        }
    }
    
    fileprivate func debug(_ response: DataResponse<Any>) {
        if let method = response.request?.HTTPMethod, let url = response.request?.URLString {
            if let httpResponse = response.response {
                print("\(method) \(url) \(httpResponse.statusCode)")
            } else {
                print("\(method) \(url) FAILED")
            }
            if let data = response.request?.HTTPBody, let requestData = String(data: data, encoding: String.Encoding.utf8) {
                print("REQUEST:\n\(requestData)")
            }
            if let data = response.data, let responseData = String(data: data, encoding: String.Encoding.utf8) {
                print("RESPONSE:\n\(responseData)")
            }
        }
    }
    
}

