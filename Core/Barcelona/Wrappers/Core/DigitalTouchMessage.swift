//
//  DigitalTouch.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import DigitalTouchShared
import Foundation
import IMCore

@objc protocol ETMessageDelegate {
    @objc func messageWillReachSizeLimit(_ message: ETMessage)
    @objc func messageWillStopPlaying(_ message: ETMessage)
    @objc func messageDidStopPlaying(_ message: ETMessage)
}

@objc class DigitalTouchMessageDelegate: NSObject, ETMessageDelegate {
    func messageWillReachSizeLimit(_ message: ETMessage) {

    }

    func messageWillStopPlaying(_ message: ETMessage) {

    }

    func messageDidStopPlaying(_ message: ETMessage) {

    }
}

public enum DigitalTouchMessage {
    case sketch(_ item: ETSketchData)
    case video(_ item: ETVideoData)
    case tap(_ item: ETTapData)
    case heartbeat(_ item: ETHeartbeatData)
    case anger(_ item: ETAngerData)
    case kiss(_ item: ETKissData)

    init?(message: ETMessage) {
        switch message {
        case let message as ETSketchMessage:
            self = .sketch(.init(message))
        case let message as ETVideoMessage:
            self = .video(.init(message))
        case let message as ETTapMessage:
            self = .tap(.init(message))
        case let message as ETHeartbeatMessage:
            self = .heartbeat(.init(message))
        case let message as ETAngerMessage:
            self = .anger(.init(message))
        case let message as ETKissMessage:
            self = .kiss(.init(message))
        default:
            return nil
        }
    }

    init?(data: Data) {
        guard let message = ETMessage.unarchive(data), let item = DigitalTouchMessage(message: message) else {
            return nil
        }

        self = item
    }
}
