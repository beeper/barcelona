//
//  ConfigurationModel.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftUI
import BarcelonaFoundation

public class ConfigurationModel: ObservableObject {
    public init(portNumber: Int, hostname: String, maxBodySize: String, publicKeyPath: String?, privateKeyPath: String?) {
        self.portNumber = portNumber
        self.hostname = hostname
        self.maxBodySize = maxBodySize
        self.publicKeyPath = publicKeyPath
        self.privateKeyPath = privateKeyPath
    }
    
    public init() {
        
    }
    
    @Published public var portNumber = 0
    @Published public var hostname = ""
    @Published public var maxBodySize = ""
    @Published public var publicKeyPath: String? = nil
    @Published public var privateKeyPath: String? = nil
}

public extension ConfigurationModel {
    func reload() -> Self {
        let config = ERHTTPServerConfiguration.storedConfiguration
        
        portNumber = config.port
        hostname = config.hostname
        maxBodySize = config.maxBodySize
        publicKeyPath = config.publicKeyPath
        privateKeyPath = config.privateKeyPath
        
        return self
    }
}
