//
//  PSKManager.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/22/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BCrypt
import KeychainSwift
import os.log

internal extension KeychainSwift {
    static var sharedInstance: KeychainSwift {
        keychain
    }
}

private let keychain = KeychainSwift(keyPrefix: "barcelona-")
private let pskDigestKey = "psk-digest"

internal class PSKManager {
    internal static let sharedInstance = PSKManager()
    
    private init() {}
    
    func reset(oldKey: String?, token: String?, newKey: String) throws {
        if let pskDigest = pskDigest {
            guard let oldKey = oldKey, let token = token, test(key: oldKey, usingDigest: pskDigest) == true, JWTManager.sharedInstance.validateToken(token, forScenario: .general) != nil else {
                throw BarcelonaError(code: 401, message: "Invalid pre-existing credentials")
            }
        }
        
        do {
            pskDigest = try CryptographyManager.sharedInstance.hash(of: newKey)
            
            JWTManager.sharedInstance.resetSigningKey()
        } catch {
            #if DEBUG
            os_log("Failed to update PSK with error %{private}@", type: .fault, error.localizedDescription)
            #endif
            
            throw BarcelonaError(code: 500, message: "Failed to update PSK")
        }
    }
    
    func test(key: String) -> Bool {
        guard let pskDigest = pskDigest else {
            return true
        }
        
        return test(key: key, usingDigest: pskDigest)
    }
    
    private func test(key: String, usingDigest pskDigest: Data) -> Bool {
        #if DEBUG
        os_log("Validating PSK", log: SecurityLog, type: .debug)
        #endif
        
        return (try? BCrypt.Hash.verify(message: key, matches: pskDigest)) ?? false
    }
    
    private var pskDigest: Data? {
        get {
            #if DEBUG
            os_log("Fetching digest from keychain", log: SecurityLog, type: .debug)
            #endif
            
            return keychain.getData(pskDigestKey)
        }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: pskDigestKey)
            } else {
                keychain.delete(pskDigestKey)
            }
        }
    }
}
