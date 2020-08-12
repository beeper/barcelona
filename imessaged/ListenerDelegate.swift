//
//  ListenerDelegate.swift
//  imessaged
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: MessageServiceProtocol.self)
        newConnection.exportedObject = MessageXPCService()
        
        newConnection.invalidationHandler = { NSLog("Connection did invalidate") }
        newConnection.interruptionHandler = { NSLog("Connection did interrupt") }
        
        newConnection.resume()
        
        return true;
    }
}
