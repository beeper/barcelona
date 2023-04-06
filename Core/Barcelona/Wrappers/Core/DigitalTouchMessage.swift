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

public enum DigitalTouchMessage {
    case sketch(_ item: ETSketchData)
    case video(_ item: ETVideoData)
    case tap(_ item: ETTapData)
    case heartbeat(_ item: ETHeartbeatData)
    case anger(_ item: ETAngerData)
    case kiss(_ item: ETKissData)
}
