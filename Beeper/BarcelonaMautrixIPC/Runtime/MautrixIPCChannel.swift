//
//  MautrixImessageIPCChannel.swift
//  BarcelonaMautrixIPC
//
//  Created by Brad Murray on 2022-11-29.
//

import Barcelona
import Combine
import OpenCombine
import ERBufferedStream
import Foundation
import Logging

let TERMINATOR = Data("\n".utf8)

public protocol MautrixIPCInputChannel {
    func listen(_ cb: @escaping (Data) -> ())
}

public protocol MautrixIPCOutputChannel {
   func write(_ data: Data)
}

private let log = Logger(label: "MautrixIPCChannel")

public class MautrixIPCChannel {
    public var receivedPayloads = Combine.PassthroughSubject<IPCPayload, Never>()
    
    // Send writes through this subject to serialize writes
    private let writeSubject = Combine.PassthroughSubject<Data, Never>()
    
    private let inputHandle: MautrixIPCInputChannel
    private let outputHandle: MautrixIPCOutputChannel
    
    let sharedBarcelonaStream: ERBufferedStream<IPCPayload> = {
        let stream = ERBufferedStream<IPCPayload>()
        stream.decoder.dateDecodingStrategy = .iso8601
        return stream
    }()
    
    var pongedOnce = false
    
    private var openCombineCancellables = Set<OpenCombine.AnyCancellable>()
    private var combineCancellables = Set<Combine.AnyCancellable>()
    
    public init(inputHandle: MautrixIPCInputChannel, outputHandle: MautrixIPCOutputChannel) {
        self.inputHandle = inputHandle
        self.outputHandle = outputHandle
        
        // Set up our reading pipeline
        
        inputHandle.listen(sharedBarcelonaStream.receive(data:))
        
        sharedBarcelonaStream.subject
            .sink { result in
                switch result {
                case .failure(let error):
                    log.warning("Failed to decode payload: \("\(error)")", source: "MautrixIPC")
                    #if DEBUG
                    log.info("Raw payload: \(String(decoding: error.rawData, as: UTF8.self))", source: "MautrixIPC")
                    #endif
                case .success(let payload):
                    #if DEBUG
                    log.info("Incoming! \(payload.command.name.rawValue) \(payload.id ?? -1)", source: "BLStandardIO")
                    #endif
                    
                    if payload.command.name != .ping, let id = payload.id, id > 1, !self.pongedOnce {
                        self.pongedOnce = true
                        self.writePayload(.init(id: 1, command: .response(.ack)))
                    }

                    if payload.command.name == .unknown {
                        // We don't still have the command that we were given, so we can't return it in the string
                        payload.fail(strategy: .command_not_found(""), ipcChannel: self)
                        return
                    }

                    switch payload.command {
                    case .ping:
                        self.pongedOnce = true
                        payload.respond(.ack, ipcChannel: self)
                        return
                    case .pre_startup_sync:
                        self.pongedOnce = true
                        if FileManager.default.fileExists(atPath: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".mxnosync").path) { payload.respond(.arbitrary(["skip_sync":true]), ipcChannel: self)
                        } else {
                            payload.respond(.ack, ipcChannel: self)
                        }
                        return
                    default:
                        break
                    }

                    if !self.pongedOnce {
                        self.writePayload(.init(id: 1, command: .response(.ack)))
                        self.pongedOnce = true
                    }
                    
                    self.receivedPayloads.send(payload)
                }
            }
            .store(in: &openCombineCancellables)
        
        let sendDispatchQueue = DispatchQueue(label: "com.barcelona.MautrixIPCChannelSendQueue")
        writeSubject
            .receive(on: sendDispatchQueue)
            .sink { self.outputHandle.write($0) }
            .store(in: &combineCancellables)
    }
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
        return encoder
    }()
    
    public func writePayload(_ payload: @autoclosure () -> IPCPayload, log: Bool = true) {
        self.writePayloads([payload()])
    }
    
    public func writePayloads(_ payloads: [IPCPayload]) {
        var data = Data()
        
        for payload in payloads {
            if payload.command.name == .message {
                log.info("Outgoing! \(payload.command.name.rawValue) \(payload.id ?? -1)")
            }
            data += try! encoder.encode(payload)
            data += TERMINATOR
        }
        
        self.writeSubject.send(data)
    }
}
