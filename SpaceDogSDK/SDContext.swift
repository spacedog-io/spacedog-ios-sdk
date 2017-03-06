//
//  SDContext.swift
//  caremen-robot
//
//  Created by philippe.rolland on 13/10/2016.
//  Copyright © 2016 in-tact. All rights reserved.
//

import Foundation

open class SDContext : CustomStringConvertible {
    
    static let InstanceId = "InstanceId"
    static let AccessToken = "AccessToken"
    static let CredentialsId = "CredentialsId"
    static let CredentialsEmail = "CredentialsEmail"
    static let ExpiresIn = "ExpiresIn"
    static let IssuedOn = "IssuedOn"
    static let DeviceId = "DeviceId"
    static let InstallationId = "InstallationId"
    
    let instanceId: String
    let appId: String
    var deviceId: String?
    var installationId: String?
    var credentials: SDCredentials?
    
    public init(instanceId: String, appId: String) {
        self.instanceId = instanceId
        self.appId = appId
    }
    
    open func setLogged(with credentials: SDCredentials) -> Void {
        self.credentials = credentials
    }
    
    open func isLogged() -> Bool {
        return self.credentials != nil
    }
    
    open func setLoggedOut() -> Void {
        self.credentials = nil
    }
    
    open var description: String {
        return "{instanceId: \(instanceId), credentials: \(credentials?.description ?? "nil"), installationId: \(installationId ?? "nil"), deviceId: \(deviceId ?? "nil")}"
    }
}
