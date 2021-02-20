//
//  ERBarcelonaAPIService.swift
//  imessage-rest
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BarcelonaVapor
import BarcelonaFoundation
import os.log

class ERBarcelonaIPCServerDelegate: BarcelonaIPCServerDelegate {
    var isRunning: Bool {
        ERHTTPServer.shared.running
    }
    
    func start(callback: @escaping () -> ()) {
//        try? ERHTTPServer.shared.start(withConfiguration: ERHTTPServerConfiguration.storedConfiguration)
        ERBarcelonaAPIService.sharedInstance.start { _ in
            callback()
        }
    }
    
    func stop(callback: @escaping () -> ()) {
        ERBarcelonaAPIService.sharedInstance.stop { _ in
            callback()
        }
    }
}

class ERBarcelonaAPIService {
    static let sharedInstance = ERBarcelonaAPIService()
    
    var listener: NSXPCListener!
    var server = BarcelonaIPCServer(delegate: ERBarcelonaIPCServerDelegate())
    
    private init() {}
    
    func killXPC() {
        listener?.invalidate()
    }
    
    func runXPC() {
        #if os(iOS)
        listener = ERMachXPCiOS(Bundle.main.bundleIdentifier!)!
        #else
        listener = NSXPCListener.service()
        #endif
        let listenerDelegate = ListenerDelegate(self)
        listener.delegate = listenerDelegate

        listener.resume()

        os_log("NSXPCListener resumed with service name %{public}@", Bundle.main.bundleIdentifier!)
        os_log("Here's my listener %{public}@", listener)
    }
    
    func start(callback: @escaping (Error?) -> ()) {
        ERBarcelonaManager.bootstrap { error in
            if let error = error {
                callback(error)
                return
            }
            
            os_log("CoreBarcelona did bootstrap, starting HTTP")
            
            do {
                let config = ERHTTPServerConfiguration.storedConfiguration
                
                try ERHTTPServer.shared.start(withConfiguration: config)
                
                os_log("BarcelonaVapor did start, running on %@:%d", config.hostname, config.port)
                
                self.server.emitRunningState()
                callback(nil)
            } catch {
                os_log("Failed to start ERHTTPServer with error %@", type: .error, error.localizedDescription)
                callback(error)
            }
        }
    }
    
    func stop(callback: @escaping (Error?) -> ()) {
        ERHTTPServer.shared.stop()
        ERBarcelonaManager.teardown()
        try! eventProcessingEventLoop.syncShutdownGracefully()
        server.emitRunningState()
        callback(nil)
        DispatchQueue.main.asyncAfter(deadline: .init(secondsFromNow: 1)) {
            exit(0)
        }
    }
}
