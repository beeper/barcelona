//
//  DuplicateMessageAggregator.swift
//  grapple
//
//  Created by Eric Rabil on 10/27/21.
//

import Foundation
import Barcelona
import Logging

protocol GrappleDebugger: AnyObject {
    func start()
    func stop()
    
    func printReport()
    func reset()
}

class DuplicateMessageAggregator: GrappleDebugger {
    static let shared = DuplicateMessageAggregator()
    
    var messages: [String: Message] = [:]
    var duplicates: [String: [Message]] = [:]
    
    let log = Logger(label: "Aggregator")
    
    private var pipeline: CBPipeline<Void>?
    
    func start() {
        stop()
        pipeline = CBDaemonListener.shared.messagePipeline.pipe(record(message:))
    }
    
    func stop() {
        pipeline?.cancel()
        pipeline = nil
    }
    
    func printReport() {
        guard duplicates.count > 0 else {
            log.info("No duplicate messages found!")
            return
        }
        
        for (messageID, messages) in duplicates {
            log.info("Found \(messages.count) duplicate events for \(messageID)")
            
            for message in messages {
                message.printOut()
            }
        }
    }
    
    func reset() {
        messages = [:]
        duplicates = [:]
    }
    
    func record(message: Message) {
        if let existing = messages[message.id] {
            duplicates[message.id, default: [existing]].append(message)
            log.warning("Found duplicate message for \(message.id)")
        } else {
            messages[message.id] = message
        }
    }
}
