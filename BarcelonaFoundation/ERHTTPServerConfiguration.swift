//
//  ERHTTPServerConfiguration.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/25/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public extension Encodable {
    var xpcObject: xpc_object_t? {
        try? XPCEncoder.encode(self)
    }
}

public extension Decodable {
    init(xpcObject: xpc_object_t) throws {
        try self.init(from: XPCDecoder(withUnderlyingMessage: xpcObject))
    }
}

public struct ERHTTPServerSSLState: Codable {
    public init(publicKeyPath: String? = nil, privateKeyPath: String? = nil) {
        self.publicKeyPath = publicKeyPath
        self.privateKeyPath = privateKeyPath
    }
    
    public var publicKeyPath: String? = nil
    public var privateKeyPath: String? = nil
}

public class ERHTTPServerConfiguration: Codable {
    public init(port: Int, hostname: String, maxBodySize: String, allowedCorsOrigin: [String]? = nil, publicKeyPath: String? = nil, privateKeyPath: String? = nil) {
        self.port = port
        self.hostname = hostname
        self.maxBodySize = maxBodySize
        self.allowedCorsOrigin = allowedCorsOrigin
        self.publicKeyPath = publicKeyPath
        self.privateKeyPath = privateKeyPath
    }
    
    public var port: Int
    public var hostname: String
    public var maxBodySize: String
    public var allowedCorsOrigin: [String]?
    public var publicKeyPath: String?
    public var privateKeyPath: String?
    
    private static let defaultPort = 8090
    private static let defaultHostname = "0.0.0.0"
    private static let defaultMaxBodySize = "10mb"
}

public func ERRunningOutOfAgent() -> Bool {
    ProcessInfo.processInfo.environment["ERRunningOutOfAgent"] != nil
}

private let sslKeychainPrefix = "ssl-"
private let sslPublicKey = "\(sslKeychainPrefix)-pubkey"
private let sslPrivateKey = "\(sslKeychainPrefix)-privkey"

public enum ERHTTPServerConfigurationEnvironmentVariable: String {
    case port = "ERHTTPPort"
    case hostname = "ERHTTPHostname"
    case maxBodySize = "ERHTTPMaxBodySize"
    case allowedCorsOrigin = "ERHTTPCORSOrigin"
    case pubkeyPath = "ERHTTPPublicKeyPath"
    case privkeyPath = "ERHTTPPrivateKeyPath"
}

private extension Dictionary where Key == String, Value == String {
    func int(forEnvironmentVariable variable: ERHTTPServerConfigurationEnvironmentVariable, defaultValue: Int) -> Int {
        var value = self[variable.rawValue].intValue
        
        if value == nil || value == 0 {
            value = defaultValue
        }
        
        return value!
    }
    
    func string(forEnvironmentVariable variable: ERHTTPServerConfigurationEnvironmentVariable, defaultValue: String) -> String {
        self[variable.rawValue] ?? defaultValue
    }
    
    func optionalString(forEnvironmentVariable variable: ERHTTPServerConfigurationEnvironmentVariable) -> String? {
        self[variable.rawValue]
    }
    
    func optionalStringArray(forEnvironmentVariable variable: ERHTTPServerConfigurationEnvironmentVariable) -> [String]? {
        if let value = self[variable.rawValue] {
            return [value]
        }
        return nil
    }
}

public extension ERHTTPServerConfiguration {
    static var environmentConiguration: ERHTTPServerConfiguration {
        let environment = ProcessInfo.processInfo.environment
        
        return ERHTTPServerConfiguration(port: environment.int(forEnvironmentVariable: .port, defaultValue: defaultPort), hostname: environment.string(forEnvironmentVariable: .hostname, defaultValue: defaultHostname), maxBodySize: environment.string(forEnvironmentVariable: .maxBodySize, defaultValue: defaultMaxBodySize), allowedCorsOrigin: environment.optionalStringArray(forEnvironmentVariable: .allowedCorsOrigin), publicKeyPath: environment.optionalString(forEnvironmentVariable: .pubkeyPath), privateKeyPath: environment.optionalString(forEnvironmentVariable: .privkeyPath))
    }
}

public extension ERHTTPServerConfiguration {
    private static func storedInt(forKey key: CodingKeys, withDefaultValue defaultValue: Int = 0) -> Int {
        var int = defaults.integer(forKey: key.stringValue)
        
        if int == 0 {
            int = defaultValue
        }
        
        return int
    }
    
    private static let defaults = UserDefaults.init(suiteName: "group.ericrabil.imessage-rest")!
    
    private static func storedString(forKey key: CodingKeys, withDefaultValue defaultValue: String? = nil) -> String? {
        defaults.string(forKey: key.stringValue) ?? defaultValue
    }
    
    private static func storedStringArray(forKey key: CodingKeys, withDefaultValue defaultValue: [String]? = nil) -> [String]? {
        defaults.stringArray(forKey: key.stringValue) ?? defaultValue
    }
    
    private static func store(_ value: Any?, forKey key: CodingKeys) {
        defaults.set(value, forKey: key.stringValue)
    }
    
    func storeToDefaults() {
        ERHTTPServerConfiguration.storedPort = port
        ERHTTPServerConfiguration.storedHostname = hostname
        ERHTTPServerConfiguration.storedMaxBodySize = maxBodySize
        ERHTTPServerConfiguration.storedAllowedCorsOrigin = allowedCorsOrigin
        ERHTTPServerConfiguration.storedPublicKeyPath = publicKeyPath
        ERHTTPServerConfiguration.storedPrivateKeyPath = privateKeyPath
    }
    
    static var storedConfiguration: ERHTTPServerConfiguration {
        ERHTTPServerConfiguration(port: storedPort, hostname: storedHostname, maxBodySize: storedMaxBodySize, allowedCorsOrigin: storedAllowedCorsOrigin, publicKeyPath: storedPublicKeyPath, privateKeyPath: storedPrivateKeyPath)
    }
    
    static var storedPort: Int {
        get {
            storedInt(forKey: .port, withDefaultValue: defaultPort)
        }
        set {
            store(newValue, forKey: .port)
        }
    }
    
    static var storedHostname: String {
        get {
            storedString(forKey: .hostname, withDefaultValue: defaultHostname)!
        }
        set {
            store(newValue, forKey: .hostname)
        }
    }
    
    static var storedMaxBodySize: String {
        get {
            storedString(forKey: .maxBodySize, withDefaultValue: defaultMaxBodySize)!
        }
        set {
            store(newValue, forKey: .maxBodySize)
        }
    }
    
    static var storedAllowedCorsOrigin: [String]? {
        get {
            storedStringArray(forKey: .allowedCorsOrigin)
        }
        set {
            store(newValue, forKey: .allowedCorsOrigin)
        }
    }
    
    static var storedPublicKeyPath: String? {
        get {
            storedString(forKey: .publicKeyPath)
        }
        set {
            store(newValue, forKey: .publicKeyPath)
        }
    }
    
    static var storedPrivateKeyPath: String? {
        get {
            storedString(forKey: .privateKeyPath)
        }
        set {
            store(newValue, forKey: .privateKeyPath)
        }
    }
}
