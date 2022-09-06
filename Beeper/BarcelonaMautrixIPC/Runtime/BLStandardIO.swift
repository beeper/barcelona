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

@_spi(unitTestInternals) public var BLPayloadIntercept: ((PBPayload) -> ())? = nil

import SwiftProtobuf

extension OutputStream {
    static let stdout: OutputStream = {
        let os = OutputStream(toFileAtPath: "/dev/stdout", append: false)!
        os.open()
        return os
    }()
}

extension InputStream {
    static let stdin: InputStream = {
        let os = InputStream(fileAtPath: "/dev/stdin")!
        os.open()
        return os
    }()
}

var nameMapCache: [String: [Int: String]] = [:]
extension _NameMap {
    func protoNameFor(rawValue: Int, cacheKey: String) -> String? {
        if let cache = nameMapCache[cacheKey] {
            return cache[rawValue]
        }
        let selfMirror = Mirror(reflecting: self)
        
        guard let numberToNameMapChild = selfMirror.children.first(where: { (name, _) -> Bool in
            return name == "numberToNameMap"
        }), let numberToNameMap = numberToNameMapChild.value as? Dictionary<Int, Any> else {
                return nil
        }

        nameMapCache[cacheKey] = numberToNameMap.compactMapValues { value in
            let valueMirror = Mirror(reflecting: value)
            
            guard let protoChild = valueMirror.children.first(where: { (name, _) -> Bool in
                return name == "proto"
            }), let stringConvertible = protoChild.value as? CustomStringConvertible else {
                return nil
            }
            
            return stringConvertible.description
        }
        return protoNameFor(rawValue: rawValue, cacheKey: cacheKey)
    }
}

struct PBPayloadCommandNameReader: SwiftProtobuf.Visitor {
    let start: Int

    mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitSingularEnumField<E>(value: E, fieldNumber: Int) throws where E : Enum {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: _ProtobufMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws where KeyType : MapKeyType, ValueType : MapValueType {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: _ProtobufEnumMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws where KeyType : MapKeyType, ValueType : Enum, ValueType.RawValue == Int {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: _ProtobufMessageMap<KeyType, ValueType>.BaseType, fieldNumber: Int) throws where KeyType : MapKeyType, ValueType : Hashable, ValueType : SwiftProtobuf.Message {
        try check(fieldNumber: fieldNumber)
    }

    mutating func visitUnknown(bytes: Data) throws {
    }

    enum Found: Error { case found(String?) }
    mutating func visitSingularMessageField<M>(value: M, fieldNumber: Int) throws where M : SwiftProtobuf.Message {
        try check(fieldNumber: fieldNumber)
    }

    func check(fieldNumber: Int) throws {
        guard fieldNumber >= start else {
            return
        }
        throw Found.found(PBPayload._protobuf_nameMap.protoNameFor(rawValue: fieldNumber, cacheKey: "PBPayloadCommandReflection"))
    }
}

/// PBPayload { int64 ID = 1; bool IsResponse = 2; oneof Command { ... }; }
extension PBPayload {
    var commandName: String? {
        var reader = PBPayloadCommandNameReader(start: 3)
        do {
            try traverse(visitor: &reader)
        } catch {
            if case PBPayloadCommandNameReader.Found.found(let name) = error {
                return name
            }
            fatalError("Error while traversing: \(error)")
        }
        return nil
    }
}

public func BLWritePayloads(_ payloads: [PBPayload]) {
    for payload in payloads {
        if !CBFeatureFlags.runningFromXcode {
            switch payload.command {
            case .log:
                break
            default:
                func printIt() {
                    CLInfo(
                        "BLStandardIO",
                        "Outgoing! %@", payload.commandName ?? "unknown"
                    )
                }
                #if DEBUG
                printIt()
                #else
                if payload.command.name != .message {
                    printIt()
                }
                #endif
            }
        }
        
        if let BLPayloadIntercept = BLPayloadIntercept {
            BLPayloadIntercept(payload)
            continue
        }
        FileHandle.standardOutput.performOnThread {
            do {
                try BinaryDelimited.serialize(message: payload, to: .stdout, partial: true)
            } catch {
                fatalError("\(error)")
                // what do we do here?
            }
        }
    }
}

public func BLWritePayload(_ payload: @autoclosure () -> PBPayload) {
    BLWritePayloads([payload()])
}

public func BLWritePayload(builder: (inout PBPayload) -> ()) {
    BLWritePayload(.with(builder))
}

private var cancellables = Set<AnyCancellable>()

var pongedOnce = false

public func BLCreatePayloadReader_(_ cb: @escaping (IPCPayload) -> ()) {
    #if false
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
            
            if payload.command.name != .ping, let id = payload.id, id > 1, !pongedOnce {
                pongedOnce = true
                // BLWritePayload(.init(id: 1, command: .response(.ack)))
                // BLWritePayload(Payload)
                
            }

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
                // BLWritePayload(.init(id: 1, command: .response(.ack)))
                BLWritePayload {
                    $0.id = 1
                    $0.command = .ack(true)
                    $0.isResponse = true
                }
                pongedOnce = true
            }
            
            cb(payload)
        }
    }, to: AnyCancellable.self).store(in: &cancellables)
    #endif
}

import BarcelonaMautrixIPCProtobuf

class IPCHandler {
    static var shared: IPCHandler!
    
    let input = FileHandle.standardInput
    let output = FileHandle.standardOutput

    let queue = DispatchQueue(label: "com.ericrabil.barcelona.mautrix.ipc", attributes: .concurrent)
    let operationQueue = OperationQueue()

    let observers = NSMutableSet()

    let callback: (PBPayload) -> ()
    
    init(callback: @escaping (PBPayload) -> ()) {
        self.callback = callback
        operationQueue.underlyingQueue = queue

        NotificationCenter.default.addObserver(self, selector: #selector(IPCHandler.readInput(from:)), name: Notification.Name.NSFileHandleDataAvailable, object: input)
        input.waitForDataInBackgroundAndNotify()
    }

    func write(payload: PBPayload) {
        
    }

    func read() {
        do {
            let payload = try BinaryDelimited.parse(messageType: PBPayload.self, from: .stdin, partial: true)
            callback(payload)
        } catch {
            CLFault("IPC", "Failed to parse payload: \("\(error)")")
        }
    }

    @objc func readInput(from notification: Notification) {
        read()
        input.waitForDataInBackgroundAndNotify()
    }
}

public func BLCreatePayloadReader(_ callback: @escaping (IPCPayload) -> ()) {
    IPCHandler.shared = .init(callback: callback)
}
