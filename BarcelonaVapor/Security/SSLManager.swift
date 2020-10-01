//
//  SSLManager.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BarcelonaFoundation
import KeychainSwift
import NIOSSL
import Vapor

private let sslKeychainPrefix = "ssl-"
private let sslPublicKey = "\(sslKeychainPrefix)-pubkey"
private let sslPrivateKey = "\(sslKeychainPrefix)-privkay"

public class SSLManager {
    public let configuration: ERHTTPServerConfiguration
    
    public init(_ configuration: ERHTTPServerConfiguration) {
        self.configuration = configuration
    }
    
    internal var tlsConfiguration: TLSConfiguration? {
        guard let publicCert = publicCert, let privateCert = privateCert else {
            return nil
        }
        
        return .forServer(certificateChain: [
            publicCert
        ], privateKey: privateCert)
    }

    public var publicKey: String? {
        get {
            configuration.publicKeyPath
        }
        set {
            configuration.publicKeyPath = newValue
        }
    }
    
    public var privateKey: String? {
        get {
            configuration.privateKeyPath
        }
        set {
            configuration.privateKeyPath = newValue
        }
    }
    
    private var publicCert: NIOSSLCertificateSource? {
        guard let publicKey = publicKey, let cert = try? NIOSSLCertificate(file: publicKey, format: .pem) else {
            return nil
        }
        
        return .certificate(cert)
    }
    
    private var privateCert: NIOSSLPrivateKeySource? {
        guard let privateKey = privateKey, let cert = try? NIOSSLPrivateKey(file: privateKey, format: .pem) else {
            return nil
        }
        
        return .privateKey(cert)
    }
}
