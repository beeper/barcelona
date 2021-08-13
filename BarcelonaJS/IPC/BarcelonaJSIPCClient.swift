//
//  BarcelonaJSIPCClient.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaIPC
import Swog

public class BarcelonaJSIPCClient {
    let sender: IPCSender<BarcelonaJSIPCPayloadType>
    let receiver = LoggingReceiver()
    
    class LoggingReceiver {
        let receiver: IPCReceiver<BarcelonaJSIPCPayloadType>
        
        init() {
            receiver = IPCReceiver.anonymousReceiver { payload, sender, receiver in
                switch payload.type {
                case .log:
                    do {
                        let loggingPayload = try payload.decode() as LoggingPayload
                        ConsoleDriver.shared.log(level: loggingPayload.level, category: loggingPayload.category, message: loggingPayload.message)
                        print("\r", terminator: "")
                    } catch {
                        return
                    }
                default:
                    break
                }
            }
        }
    }
    
    public init?() {
        guard let sender = IPCSender<BarcelonaJSIPCPayloadType>.serverSender(named: "com.barcelona.js-server") else {
            return nil
        }
        
        self.sender = sender
    }
    
    public func execute(_ code: String) -> String {
        try! self.sender.send(contentBlockingUntilReply: code, type: .execute).0.decode()
    }
    
    public func autocomplete(text: String) -> [String] {
        try! sender.send(contentBlockingUntilReply: text, type: .autocomplete).0.decode()
    }
    
    public func enableLogging() -> Void {
        self.sender.send(content: true, type: .log, withReceiver: self.receiver.receiver)
    }
    
    public func disableLogging() -> Void {
        self.sender.send(content: false, type: .log, withReceiver: self.receiver.receiver)
    }
}
