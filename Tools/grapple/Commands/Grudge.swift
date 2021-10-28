//
//  Grudge.swift
//  grapple
//
//  Created by Eric Rabil on 10/27/21.
//

import Foundation
import SwiftCLI
import Yammit
import Swog

struct GrudgeConfiguration: Codable, Configuration {
    static var path: String = ""
    
    var duplicateDetector: Bool?
    var automaticSending: AutomatedMessageSender.Configuration?
    var readReceipts: ReadReceiptTester.Configuration?
    
    var debuggers: [GrappleDebugger] {
        var debuggers: [GrappleDebugger] = []
        
        if duplicateDetector == true {
            debuggers.append(DuplicateMessageAggregator.shared)
        }
        
        if let automaticSending = automaticSending {
            debuggers.append(AutomatedMessageSender.shared)
            AutomatedMessageSender.shared.configuration = automaticSending
        }
        
        if let readReceipts = readReceipts {
            debuggers.append(ReadReceiptTester.shared)
            ReadReceiptTester.shared.config = readReceipts
        }
        
        return debuggers
    }
}

class Grudge: BarcelonaCommand {
    let name = "grudge"
    
    @Param(completion: .filename) var configuration: String
    
    static let shared = Grudge()
    
    var debuggers: [GrappleDebugger] = []
    
    func interrupt() {
        for debugger in debuggers {
            debugger.stop()
        }
        
        for debugger in debuggers {
            debugger.printReport()
        }
        
        for debugger in debuggers {
            debugger.reset()
        }
    }
    
    func execute() throws {
        LoggingDrivers = [OSLogDriver.shared, ConsoleDriver.shared]
        
        GrudgeConfiguration.path = configuration
        
        debuggers = GrudgeConfiguration.load().debuggers
        
        for debugger in debuggers {
            debugger.start()
        }
        
        signal(SIGINT) { _ in
            Grudge.shared.interrupt()
            exit(0)
        }
    }
}
