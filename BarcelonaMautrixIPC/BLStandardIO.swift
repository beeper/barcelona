//
//  BLMautrixTask.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

private extension FileHandle {
    func handleDataAsynchronously(_ cb: @escaping (Data) -> ()) {
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: self, queue: .current) { notif in
            let handle = notif.object as! FileHandle
            cb(handle.availableData)
            handle.waitForDataInBackgroundAndNotify()
        }
        waitForDataInBackgroundAndNotify()
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

private let jujitsuEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    
    encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
    encoder.outputFormatting = .prettyPrinted
    
    return encoder
}()

private var BL_IS_WRITING_META_PAYLOAD = false

public func BLWritePayload(_ payload: IPCPayload) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
    
    if payload.command.name != .log {
        BLJujitsuClient.shared.sendEvent(named: "ipc", payload: [
            "direction": "toMautrix",
            "json": String(data: try! jujitsuEncoder.encode(payload), encoding: .utf8)!
        ])
    }
    
    if !BL_IS_WRITING_META_PAYLOAD, payload.command.name != .log {
        BL_IS_WRITING_META_PAYLOAD = true
        CLInfo(
            "BLStandardIO",
            "Outgoing! %@ %d", payload.command.name.rawValue, payload.id ?? -1
        )
        BL_IS_WRITING_META_PAYLOAD = false
    }
    
    FileHandle.standardOutput.write(try! encoder.encode(payload))
}

public func BLCreatePayloadReader(_ cb: @escaping (IPCPayload) -> ()) {
    FileHandle.standardInput.handleDataAsynchronously { data in
        guard !data.isEmpty else {
            return
        }
        
        let chunks = data.split(separator: BLPayloadSeparator)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for chunk in chunks {
            do {
                let payload = try JSONDecoder().decode(IPCPayload.self, from: chunk)
                
                BLJujitsuClient.shared.sendEvent(named: "ipc", payload: [
                    "direction": "toBarcelona",
                    "json": String(data: try! jujitsuEncoder.encode(payload), encoding: .utf8)!
                ])
                
                CLInfo("BLStandardIO", "Incoming! %@ %d", payload.command.name.rawValue, payload.id ?? -1)
                
                cb(payload)
            } catch {
                CLWarn("MautrixIPC", "Failed to decode payload: %@", "\(error)")
                CLInfo("MautrixIPC", "Raw payload: %@", String(data: chunk, encoding: .utf8)!)
            }
        }
    }
}
