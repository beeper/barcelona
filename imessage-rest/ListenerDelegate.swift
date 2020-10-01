//
//  MessageXPCDelegate.swift
//  imessage-rest
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import os.log

@objc(ERListenerDelegate)
public class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    var apiService: ERBarcelonaAPIService
    
    init(_ apiService: ERBarcelonaAPIService) {
        self.apiService = apiService
    }
    
    @objc public func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: MessageServiceProtocol.self)
        newConnection.exportedObject = MessageXPCService()
        
        newConnection.invalidationHandler = {
            os_log("XPC Connection did invalidate")
        }
        newConnection.interruptionHandler = { os_log("XPC Connection did interrupt") }
        
        os_log("Accepting XPC connection with PID %d", newConnection.processIdentifier)
        
        newConnection.resume()
        
        return true
    }
}
