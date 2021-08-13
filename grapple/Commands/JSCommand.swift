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
                let thread = JSThread()
                let server = BarcelonaJSIPCServer(context: thread)
                
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
            let thread = JSThread()
            
            LoggingDrivers = [OSLogDriver.shared]
            
            Thread {
                while let js = readLine() {
                    print(thread.execute(js))
                }
            }.start()
        }
    }
    
    public let children: [Routable] = [
        ServeCommand(), RemoteREPLCommand(), REPLCommand()
    ]
}
