//
//  JSCommand.swift
//  grapple
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftCLI
import JavaScriptCore
import Barcelona
import IMCore
import BarcelonaJS
import LineNoise

public class JSCommand: CommandGroup {
    public let shortDescription: String = "commands for the js apis"
    public let name = "js"
    
    public class ServeCommand: Command {
        public let name = "srv"
        
        public func execute() throws {
            Thread {
                let server = BarcelonaJSIPCServer(context: JBLCreateJSContext())
                
                RunLoop.current.run()
            }.start()
        }
    }
    
    public class RemoteREPLCommand: Command {
        public let name = "remote"
        
        public func execute() throws {
            LoggingDrivers = [OSLogDriver.shared]
            
            Thread {
                guard let client = BarcelonaJSIPCClient() else {
                    exit(-1)
                }
                
                let ln = LineNoise()
                
                ln.setCompletionCallback { text in
                    client.autocomplete(text: text)
                }
                
                while let code = try? ln.getLine(prompt: ">>> ") {
                    ln.addHistory(code)
                    
                    switch code {
                    case ".log on":
                        client.enableLogging()
                    case ".log off":
                        client.disableLogging()
                    case ".exit":
                        exit(0)
                    case ".apis":
                        print("\r\n" + client.autocomplete(text: "JBL").joined(separator: ", "))
                    default:
                        print("\r\n" + client.execute(code).replacingOccurrences(of: "\n", with: "\r\n"), terminator: "\r\n")
                    }
                }
            }.start()
        }
    }
    
    public class REPLCommand: Command {
        public let name = "repl"
        
        public func execute() throws {
            let context = JBLCreateJSContext()
            
            LoggingDrivers = [OSLogDriver.shared]
            
            Thread {
                while let js = readLine() {
                    print(context.evaluateScript(atomically: js).inspectionString ?? "undefined")
                }
            }.start()
        }
    }
    
    public class RunCommand: Command {
        public let name  = "run"
        
        @Param(completion: .filename)
        public var path: String
        
        public func execute() throws {
            let script = try Data(contentsOf: URL(fileURLWithPath: path))
            
            let context = JBLCreateJSContext()
            
            context["exit"] = JSValue(jsValueRef: JSObjectMakeFunctionWithCallback(context.jsGlobalContextRef, "exit".js) { ctx, function, this, argumentCount, arguments, exception in
                if argumentCount == 1, let exitRef = arguments?.pointee, JSValueIsNumber(ctx, exitRef) {
                    exit(Int32(JSValueToNumber(ctx, exitRef, exception)))
                } else {
                    exit(0)
                }
            }, in: context)
            
            context.evaluateScript(String(decoding: script, as: UTF8.self))
        }
    }
    
    public let children: [Routable] = [
        ServeCommand(), RemoteREPLCommand(), REPLCommand(), RunCommand()
    ]
}

extension String {
    @_transparent
    var js: JSStringRef {
        JSStringCreateWithCFString(self as CFString)
    }
}
