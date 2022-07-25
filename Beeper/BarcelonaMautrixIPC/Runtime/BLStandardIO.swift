//
//  BLMautrixTask.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreFoundation
import BarcelonaFoundation
import Barcelona
import Combine
import ERBufferedStream

public extension FileHandle {
    private static var threads: [FileHandle: Thread] = [:]
    private static var callbacks: [FileHandle: (Data) -> ()] = [:]
    private static var runLoops: [FileHandle: CFRunLoop] = [:]
    
    var dataCallback: (Data) -> () {
        get {
            Self.callbacks[self] ?? { _ in }
        }
        set {
            Self.callbacks[self] = newValue
        }
    }
    
    private var thread: Thread {
        if let thread = Self.threads[self] {
            return thread
        }
        
        let thread = Thread {
            Self.runLoops[self] = CFRunLoopGetCurrent()
            
            RunLoop.current.schedule {
                NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: self, queue: nil) { notif in
                    let handle = notif.object as! FileHandle
                    self.dataCallback(handle.availableData)
                    handle.waitForDataInBackgroundAndNotify()
                }
                self.waitForDataInBackgroundAndNotify()
            }
            
            RunLoop.current.run()
        }
        Self.threads[self] = thread
        
        return thread
    }
    
    func performOnThread(_ callback: @escaping () -> ()) {
        guard let runLoop = Self.runLoops[self] else {
            callback()
            return
        }
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue, callback)
        CFRunLoopWakeUp(runLoop)
    }
    
    func handleDataAsynchronously(_ cb: @escaping (Data) -> ()) {
        dataCallback = cb
        thread.start()
    }
}

private extension Data {
    func split(separator: Data) -> [Data] {
        var chunks: [Data] = []
        var pos = startIndex
        // Find next occurrence of separator after current position:
        while let r = self[pos...].range(of: separator) {
            // Append if non-empty:
            if r.lowerBound > pos {
                chunks.append(self[pos..<r.lowerBound])
            }
            // Update current position:
            pos = r.upperBound
        }
        // Append final chunk, if non-empty:
        if pos < endIndex {
            chunks.append(self[pos..<endIndex])
        }
        return chunks
    }
}

private let BLPayloadSeparator = "\n".data(using: .utf8)!

extension Formatter {
    static let iso8601withFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSxxx"
        return formatter
    }()
}

extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        var container = $1.singleValueContainer()
        try container.encode(Formatter.iso8601withFractionalSeconds.string(from: $0))
    }
}

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = Formatter.iso8601withFractionalSeconds.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container,
                  debugDescription: "Invalid date: " + string)
        }
        return date
    }
}

private var BL_IS_WRITING_META_PAYLOAD = false
private let TERMINATOR = Data("\n".utf8)

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
    
    if CBFeatureFlags.runningFromXcode {
        encoder.outputFormatting = .prettyPrinted
    }
    
    return encoder
}()

@_spi(unitTestInternals) public var BLPayloadIntercept: ((IPCPayload) -> ())? = nil

public func BLWritePayloads(_ payloads: [IPCPayload], log: Bool = true) {
    var data = Data()
    
    for payload in payloads {
        if !CBFeatureFlags.runningFromXcode && log {
            func printIt() {
                CLInfo(
                    "BLStandardIO",
                    "Outgoing! %@ %ld", payload.command.name.rawValue, payload.id ?? -1
                )
            }
            #if DEBUG
            printIt()
            #else
            if payload.command.name == .message {
                printIt()
            }
            #endif
        }
        
        if let BLPayloadIntercept = BLPayloadIntercept {
            BLPayloadIntercept(payload)
            continue
        }
        data += try! encoder.encode(payload)
        data += TERMINATOR
    }
    
    if BLPayloadIntercept == nil {
        FileHandle.standardOutput.performOnThread {
            FileHandle.standardOutput.write(data)
            
            #if DEBUG
            if BLMetricStore.shared.get(key: .shouldDebugPayloads) ?? false {
                FileHandle.standardOutput.write(TERMINATOR)
            }
            #endif
        }
    }
}

public func BLWritePayload(_ payload: @autoclosure () -> IPCPayload, log: Bool = true) {
    BLWritePayloads([payload()], log: log)
}

private var cancellables = Set<AnyCancellable>()

let sharedBarcelonaStream: ERBufferedStream<IPCPayload> = {
    let stream = ERBufferedStream<IPCPayload>()
    stream.decoder.dateDecodingStrategy = .iso8601
    return stream
}()

var pongedOnce = false

public func BLCreatePayloadReader(_ cb: @escaping (IPCPayload) -> ()) {
    FileHandle.standardInput.handleDataAsynchronously(sharedBarcelonaStream.receive(data:))
    
    unsafeBitCast(sharedBarcelonaStream.subject.sink { result in
        switch result {
        case .failure(let error):
            CLWarn("MautrixIPC", "Failed to decode payload: %@", "\(error)")
            #if DEBUG
            CLInfo("MautrixIPC", "Raw payload: %@", String(decoding: error.rawData, as: UTF8.self))
            #endif
        case .success(let payload):
            #if DEBUG
            CLInfo("BLStandardIO", "Incoming! %@ %ld", payload.command.name.rawValue, payload.id ?? -1)
            #endif

            switch payload.command {
            case .ping:
                pongedOnce = true
                payload.respond(.ack)
                return
            case .pre_startup_sync:
                pongedOnce = true
                if FileManager.default.fileExists(atPath: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".mxnosync").path) {
                    payload.respond(.arbitrary(["skip_sync":true]))
                } else {
                    payload.respond(.ack)
                }
                return
            default:
                break
            }

            if !pongedOnce {
                BLWritePayload(.init(id: 1, command: .response(.ack)))
                pongedOnce = true
            }
            
            cb(payload)
        }
    }, to: AnyCancellable.self).store(in: &cancellables)
}
