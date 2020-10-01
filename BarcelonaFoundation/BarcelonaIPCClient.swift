//
//  BarcelonaIPCClient.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import AppSupport
import os.log

public protocol BarcelonaIPCClientDelegate {
    func runningStateChanged(newState: Bool)
}

internal typealias BarcelonaIPCHandler = (NSDictionary?) -> NSDictionary?
internal typealias BarcelonaNotificationHandler = (NSDictionary?) -> ()

internal enum BarcelonaIPCRole {
    case server
    case client
}

public class BarcelonaIPCCore: NSObject {
    private var messageHandlers: [String: BarcelonaIPCHandler] = [:]
    
    internal let messagingCenter = CPDistributedMessagingCenter(named: BarcelonaIPCServerName)
    internal let clientMessagingCenter = CPDistributedMessagingCenter(named: BarcelonaIPCClientName)
    
    internal init(role: BarcelonaIPCRole) {
        super.init()
        
        #if os(iOS)
        ERTouchCPDistributedMessagingCenterInappropriately(messagingCenter)
        ERTouchCPDistributedMessagingCenterInappropriately(clientMessagingCenter)
        #endif
        
        switch role {
        case .server:
            DispatchQueue(label: "CPDistributedMessagingCenter").sync {
                messagingCenter.runServerOnCurrentThread()
            }
            break
        case .client:
            DispatchQueue(label: "CPDistributedMessagingCenter").sync {
                clientMessagingCenter.runServerOnCurrentThread()
            }
            break
        }
        
        BarcelonaIPCMessageName.allCases.forEach {
            messagingCenter.register(forMessageName: $0.rawValue, target: self, selector: #selector(BarcelonaIPCCore.handle(messageNamed:withUserInfo:)))
        }
        
        BarcelonaIPCNotification.allCases.forEach {
            clientMessagingCenter.register(forMessageName: $0.synthesizedMessageName, target: self, selector: #selector(BarcelonaIPCCore.handle(messageNamed:withUserInfo:)))
        }
    }
    
    internal func register(forNotification notificationName: BarcelonaIPCNotification, handler: @escaping BarcelonaNotificationHandler) {
        messageHandlers[notificationName.synthesizedMessageName] = {
            handler($0)
            return nil
        }
    }
    
    internal func register(forMessageName messageName: BarcelonaIPCMessageName, handler: @escaping BarcelonaIPCHandler) {
        register(forName: messageName.rawValue, handler: handler)
    }
    
    internal func register(forName name: String, handler: @escaping BarcelonaIPCHandler) {
        messageHandlers[name] = handler
    }
    
    internal func emit(notification: BarcelonaIPCNotification, payload: NSDictionary?) {
        os_log("Emitting synthesized notification %{public}@ over messaging center with payload %@", log: IPCLog,  notification.rawValue, payload ?? "<<none>>")
        clientMessagingCenter.sendMessageName(notification.synthesizedMessageName, userInfo: payload)
    }
    
    internal func emit<P: Codable>(notification: BarcelonaIPCNotification, payload: P) {
        emit(notification: notification, payload: try! NSDictionaryEncoder.encode(payload))
    }
    
    internal func sendMessage<P: Codable>(_ messageName: BarcelonaIPCMessageName, payload: P) {
        sendMessage(messageName, payload: try! NSDictionaryEncoder.encode(payload))
    }
    
    internal func sendMessage(_ messageName: BarcelonaIPCMessageName, payload: NSDictionary? = nil) {
        os_log("Sending message to IPC server with name %{public}@ and payload %@", log: IPCLog, messageName.rawValue, payload ?? "nil")
        messagingCenter.sendMessageName(messageName.rawValue, userInfo: payload)
    }
    
    internal func sendMessageExpectingReply<P: Codable>(_ messageName: BarcelonaIPCMessageName, payload: P) -> NSDictionary? {
        sendMessageExpectingReply(messageName, payload: try! NSDictionaryEncoder.encode(payload))
    }
    
    internal func sendMessageExpectingReply(_ messageName: BarcelonaIPCMessageName, payload: NSDictionary? = nil) -> NSDictionary? {
        os_log("Sending message to IPC server with name %{public}@ and payload %@", log: IPCLog, messageName.rawValue, payload ?? "nil")
        return messagingCenter.sendMessageAndReceiveReplyName(messageName.rawValue, userInfo: payload) as? NSDictionary
    }
    
    @objc private func handle(messageNamed name: String, withUserInfo userInfo: NSDictionary? = nil) -> NSDictionary? {
        os_log("Received message from CPDistributedMessagingCenter with name %{public}@", log: IPCLog, name)
        guard let handler = messageHandlers[name] else {
            os_log("No message handler registered for message %{public}@, I have %@", log: IPCLog, name, Array(messageHandlers.keys))
            return nil
        }
        
        let result = handler(userInfo)
        os_log("Finished calling message handler for %{public}@ with result %@", log: IPCLog, name, result ?? "nil")
        return result
    }
}

@objc(BarcelonaIPCClient)
public class BarcelonaIPCClient: BarcelonaIPCCore {
    public var delegate: BarcelonaIPCClientDelegate
    
    public init(delegate: BarcelonaIPCClientDelegate) {
        self.delegate = delegate
        
        super.init(role: .client)
        
        register(forNotification: .runningStateChanged) { dict in
            guard let dict = dict, let runningStateMessage = try? NSDictionaryDecoder.decode(BarcelonaIsRunningMessage.self, value: dict) else {
                return
            }
            
            delegate.runningStateChanged(newState: runningStateMessage.isRunning)
        }
    }
    
    public func isRunning() -> Bool {
        guard let response = sendMessageExpectingReply(.isRunning), let isRunningPayload = try? NSDictionaryDecoder.decode(BarcelonaIsRunningMessage.self, value: response) else {
            return false
        }
        
        os_log("Got reply from IPC server, isRunning == %{public}@", log: IPCLog, response);
        
        return isRunningPayload.isRunning
    }
    
    public func start() {
        sendMessage(.start)
    }
    
    public func stop() {
        sendMessage(.stop)
    }
}
