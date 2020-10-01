//
//  BarcelonaIPC.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import AppSupport
import os.log

public let BarcelonaIPCServerName = "com.ericrabil.barcelona.ipc"
public let BarcelonaIPCClientName = "com.ericrabil.barcelona.client"

public enum BarcelonaIPCMessageName: String, CaseIterable {
    case isRunning
    case stop
    case start
}

public enum BarcelonaIPCNotification: String, CaseIterable {
    case runningStateChanged = "ERBarcelonaRunningStateChanged"
    
    public var notification: Notification.Name {
        .init(rawValue)
    }
    
    internal var synthesizedMessageName: String {
        "ERSynthesizedNotification\(rawValue)"
    }
}

public struct BarcelonaIsRunningMessage: Codable {
    public init(isRunning: Bool) {
        self.isRunning = isRunning
    }
    
    public var isRunning: Bool
}

public protocol BarcelonaIPCServerDelegate {
    var isRunning: Bool { get }
    func start(callback: @escaping () -> ())
    func stop(callback: @escaping () -> ())
}

@objc(BarcelonaIPCServer)
public class BarcelonaIPCServer: BarcelonaIPCCore {
    public var delegate: BarcelonaIPCServerDelegate
    
    private var isRunning: Bool {
        delegate.isRunning
    }
    
    private var isRunningMessage: BarcelonaIsRunningMessage {
        BarcelonaIsRunningMessage(isRunning: isRunning)
    }
    
    private var isRunningDictionary: NSDictionary {
        try! NSDictionaryEncoder.encode(isRunningMessage)
    }
    
    public init(delegate: BarcelonaIPCServerDelegate) {
        self.delegate = delegate
        
        super.init(role: .server)
        
        os_log("Barcelona IPC server is now running", log: IPCLog)
        
        register(forMessageName: .isRunning) { _ in
            self.isRunningDictionary
        }
        
        register(forMessageName: .start) { _ in
            self.delegate.start {
            }
            return nil
        }
        
        register(forMessageName: .stop) { _ in
            self.delegate.stop {
            }
            return nil
        }
    }
    
    public func emitRunningState() {
        emit(notification: .runningStateChanged, payload: isRunningMessage)
    }
}
