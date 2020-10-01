//
//  AppController.swift
//  imessage-rest-mac-controller
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import os.log

extension NotificationCenter {
    func post<P: Encodable>(name: BarcelonaIPCNotification, userInfo: P) {
        post(name: name.notification, object: nil, userInfo: try! NSDictionaryEncoder.encode(userInfo) as! [AnyHashable : Any])
    }
    
    func addObserver<P: Decodable>(forName name: BarcelonaIPCNotification, model: P.Type, using callback: @escaping (P) -> ()) {
        addObserver(forName: name.notification, object: nil, queue: nil) {
            if let obj = try? $0.decoding(userInfoToType: model) {
                callback(obj)
            }
        }
    }
}

extension Notification {
    func decoding<P: Decodable>(userInfoToType type: P.Type) throws -> P? {
        guard let userInfo = userInfo as NSDictionary? else {
            return nil
        }
        
        return try NSDictionaryDecoder.decode(type, value: userInfo)
    }
}

class ERBarcelonaIPCClientDelegate: BarcelonaIPCClientDelegate {
    func runningStateChanged(newState: Bool) {
        NotificationCenter.default.post(name: .runningStateChanged, userInfo: BarcelonaIsRunningMessage(isRunning: newState))
    }
}

class RemoteController {
    public static let sharedInstance = RemoteController()
    
    private init() {
        remoteSession = BarcelonaIPCClient(delegate: delegate)
    }
    
    private var connection: NSXPCConnection!
    private var service: MessageServiceProtocol!
    fileprivate var delegate = ERBarcelonaIPCClientDelegate()
    public var remoteSession: BarcelonaIPCClient
    
    public func disconnect() {
        #if os(iOS)
        #else
        connection?.suspend()
        #endif
    }
    
    public func connect(mach: Bool = false) {
        #if os(iOS)
        #else
        if mach {
            connection = NSXPCConnection(machServiceName: MachServiceName)
        } else {
            connection = NSXPCConnection(serviceName: MachServiceName)
        }
        
        connection.remoteObjectInterface = .init(with: MessageServiceProtocol.self)
        
        connection.invalidationHandler = {
            os_log("NSXPCConnection to %{public}@ was invalidated!!! WTF!!!", MachServiceName)
        }
        
        connection.interruptionHandler = {
            os_log("NSXPCConnection to %{public}@ was interrupted!!! K-WORDING MYSELF!!!", MachServiceName)
        }
        
        service = connection.remoteObjectProxyWithErrorHandler { error in
            os_log("Encountered an error while using the remote object proxy?! WTF?! %{public}@", error.localizedDescription)
        } as? MessageServiceProtocol
        
        connection.resume()
        #endif
    }
}

extension RemoteController {
    func start() {
        #if os(iOS)
        remoteSession.start()
        #else
        service.startServer { _ in
            
        }
        #endif
    }
    
    func stop() {
        #if os(iOS)
        remoteSession.stop()
        #else
        service.stopServer { error in
            self.service.terminate {
                
            }
        }
        #endif
    }
    
    func isRunning(callback: @escaping (Bool) -> ()) {
        os_log("i check if running")
        callback(remoteSession.isRunning())
    }
}
