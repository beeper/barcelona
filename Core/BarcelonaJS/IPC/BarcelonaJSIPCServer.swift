//
//  BarcelonaJSIPCServer.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaIPC
import Swog

public class BarcelonaJSIPCServer {
    let receiver: IPCReceiver<BarcelonaJSIPCPayloadType>
    
    class BarcelonaJSIPCLogPipe: LoggingDriver {
        var isMounted: Bool {
            LoggingDrivers.contains(where: { $0 is BarcelonaJSIPCLogPipe })
        }
        
        var outlets = Set<IPCSender<BarcelonaJSIPCPayloadType>>() {
            didSet {
                if outlets.count > 0, !isMounted {
                    LoggingDrivers.append(self)
                } else if outlets.count == 0, isMounted {
                    LoggingDrivers.removeAll(where: { $0 is BarcelonaJSIPCLogPipe })
                }
            }
        }
        
        public func log(level: LoggingLevel, fileID: StaticString, line: Int, function: StaticString, dso: UnsafeRawPointer, category: StaticString, message: StaticString, args: [CVarArg]) {
            self.outlets.forEach { outlet in
                outlet.send(content: LoggingPayload(level: level, message: String(format: String(message), arguments: args), category: String(category)), type: .log)
            }
        }
        
        public func log(level: LoggingLevel, fileID: StaticString, line: Int, function: StaticString, dso: UnsafeRawPointer, category: StaticString, message: BackportedOSLogMessage) {
            self.outlets.forEach { outlet in
                outlet.send(content: LoggingPayload(level: level, message: message.render(level: .auto), category: String(category)), type: .log)
            }
        }
    }
    
    private let logPipe = BarcelonaJSIPCLogPipe()
    
    public init(context: JSContext) {
        let logPipe = logPipe
        receiver = IPCReceiver.serverReceiver(named: "com.barcelona.js-server") { payload, sender, receiver in
            switch payload.type {
            case .execute:
                do {
                    sender?.send(content: context.evaluateScript(atomically: try payload.decode()).inspectionString ?? "undefined", type: .result)
                } catch {
                    sender?.send(content: "failed to decode payload", type: .result)
                }
            case .log:
                // signal to enable/disable logging on the sender
                guard let enabled: Bool = try? payload.decode(), let sender = sender else {
                    break
                }
                
                if enabled {
                    logPipe.outlets.insert(sender)
                } else {
                    logPipe.outlets.remove(sender)
                }
            case .autocomplete:
                guard let line = try? payload.decode() as String else {
                    sender?.send(content: [String](), type: .autocomplete)
                    return
                }
                
                sender?.send(content: context.completion(forLine: line), type: .autocomplete)
            default:
                break
            }
        }
    }
}
