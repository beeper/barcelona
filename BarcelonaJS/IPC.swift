//
//  IPC.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaIPC
import BarcelonaFoundation
import JavaScriptCore

public enum BarcelonaJSIPCPayloadType: UInt, Codable {
    case execute = 0
    case result = 1
    case log = 2
    case autocomplete = 4
}

internal struct JBLLoggingData: Codable {
    let level: LoggingLevel
    let message: String
    let category: String
}

private let debugQueue = DispatchQueue(label: "com.barcelona.jbl-debug")
private let simpleExpressionRE = try! NSRegularExpression(pattern: #"/(?:[a-zA-Z_$](?:\w|\$)*\??\.)*[a-zA-Z_$](?:\w|\$)*\??\.?$/"#, options: [])

extension JSValue {
    var isFunction: Bool {
        guard isObject else {
            return false
        }
        
        return JSObjectIsFunction(context.jsGlobalContextRef, jsValueRef)
    }
    
    var getOwnPropertyNames: JSValue {
        context.evaluateScript("Object.getOwnPropertyNames")!
    }
    
    var propertyNames: [String] {
        guard !isNull() else {
            return []
        }
        
        return getOwnPropertyNames.call(withArguments: [self]).toArray()?.compactMap { $0 as? String } ?? []
    }
    
    var prototype: JSValue? {
        guard !isNull(), let ref = JSObjectGetPrototype(context.jsGlobalContextRef, jsValueRef) else {
            return nil
        }
        
        return JSValue(jsValueRef: ref, in: context)
    }
    
    subscript(key: String) -> JSValue? {
        guard isObject, !isNull() else {
            return nil
        }
        
        return JSValue(jsValueRef: JSObjectGetProperty(context.jsGlobalContextRef, jsValueRef, JSStringCreateWithCFString(key as CFString), nil), in: context)
    }
}

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
                outlet.send(content: JBLLoggingData(level: level, message: String(format: String(message), arguments: args), category: String(category)), type: .log)
            }
        }
    }
    
    private let logPipe = BarcelonaJSIPCLogPipe()
    
    public init(context: JSThread) {
        let logPipe = logPipe
        receiver = IPCReceiver.serverReceiver(named: "com.barcelona.js-server") { payload, sender, receiver in
            switch payload.type {
            case .execute:
                do {
                    sender?.send(content: context.execute(try payload.decode()), type: .result)
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
                
                sender?.send(content: context.context.completion(forLine: line), type: .autocomplete)
            default:
                break
            }
        }
    }
}

public class BarcelonaJSIPCLoggingReceiver {
    public let receiver: IPCReceiver<BarcelonaJSIPCPayloadType>
    
    public init() {
        receiver = IPCReceiver.anonymousReceiver { payload, sender, receiver in
            switch payload.type {
            case .log:
                do {
                    let loggingPayload = try payload.decode() as JBLLoggingData
                    ConsoleDriver.shared.log(level: loggingPayload.level, category: loggingPayload.category, message: loggingPayload.message)
                } catch {
                    return
                }
            default:
                break
            }
        }
    }
}

public class BarcelonaJSIPCClient {
    let sender: IPCSender<BarcelonaJSIPCPayloadType>
    let receiver = BarcelonaJSIPCLoggingReceiver()
    
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
