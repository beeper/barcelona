//
//  BLMautrixTask.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

private func BLMautrixTaskProcessEnvironment() -> [String: String] {
    var env = ProcessInfo.processInfo.environment
    env["NSUnbufferedIO"] = "YES"
    
    return env
}

public class BLMautrixTask {
    public static let shared = BLMautrixTask()
    public let process: Process
    
    private let writePipe: Pipe
    private let readPipe: Pipe
    private let errorPipe: Pipe
    
    public init() {
        process = .init()
        process.launchPath = BLMautrixRuntimeConfig.shared.mautrixLaunchPath
        
        if let mautrixConfigURL = BLMautrixRuntimeConfig.shared.mautrixConfigURL {
            process.arguments = ["-u".appendingFormat("%@", mautrixConfigURL), "--output-redirect"]
        }
        
        process.currentDirectoryPath = BLMautrixRuntimeConfig.shared.mautrixCWD
        process.environment = BLMautrixTaskProcessEnvironment()
        
        writePipe = .init()
        process.standardInput = writePipe
        
        readPipe = .init()
        readPipe.fileHandleForReading.readabilityHandler = { file in
            
        }
        
        process.standardOutput = readPipe
        
        errorPipe = .init()
        errorPipe.fileHandleForReading.readabilityHandler = { file in
            
        }
        
        process.standardError = errorPipe
    }
}
