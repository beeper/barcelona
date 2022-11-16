//
//  MXFeatureFlags.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 2/3/22.
//

import Foundation
import FeatureFlags

public class MXFeatureFlags: FlagProvider {
    public static let shared = MXFeatureFlags()
    
    public let suiteName: String = "com.beeper.mautrix-imessage"
    
    @FeatureFlag("read-helper", defaultValue: true)
    public var enableReadHelpers: Bool
    
    @FeatureFlag("merged-chats", defaultValue: false)
    public var mergedChats: Bool
}
