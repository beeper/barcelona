//
//  CryptographyManager.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/22/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Security
import BCrypt
import os.log

#if DEBUG
internal let SecurityLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "BarcelonaSecurity")
#endif

private extension Data {
    static func randomBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard status == errSecSuccess else {
            throw BarcelonaError(code: 500, message: "Failed to generate secure-random bytes")
        }
        
        return bytes
    }
    
    static func random(count: Int) throws -> Data {
        return Data(try randomBytes(count: count))
    }
}

private let HashingComplexity: UInt = 3

internal class CryptographyManager {
    internal static let sharedInstance = CryptographyManager()
    
    private init() {}
    
    func hash(of bytes: BytesConvertible) throws -> Data {
        return try hash(of: try bytes.makeBytes())
    }
    
    func hash(of keyBytes: Bytes) throws -> Data {
        #if DEBUG
        os_log("Generating salt for hash", log: SecurityLog, type: .debug)
        #endif
        
        let salt = try makeSalt()
        
        #if DEBUG
        os_log("Generating signing key", log: SecurityLog, type: .debug)
        #endif
        
        return Data(try BCrypt.Hash.make(message: keyBytes, with: salt))
    }
    
    func randomHash() throws -> Data {
        #if DEBUG
        os_log("Generating random data for hash", log: SecurityLog, type: .debug)
        #endif
        
        return try hash(of: try Data.randomBytes(count: 16))
    }
    
    func makeSalt() throws -> Salt {
        return try Salt(.two(.y), cost: HashingComplexity, bytes: try Data.randomBytes(count: 16))
    }
}
