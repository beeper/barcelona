//
//  BLMautrixRuntimeConfig.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

private let BLLaunchPathKey = "launchpath"
private let BLConfigURLKey = "configurl"
private let BLCWDKey = "cwd"

private extension String {
    var expandingTildeInPath: String {
        return (self as NSString).expandingTildeInPath
    }
}

public class BLMautrixRuntimeConfig {
    public static let shared = BLMautrixRuntimeConfig()
    
    public var mautrixLaunchPath: String {
        get {
            UserDefaults.standard.string(forKey: BLLaunchPathKey) ?? "/Users/ericrabil/eric.other/mautrix-imessage/mautrix-imessage"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: BLLaunchPathKey)
        }
    }
    
    public var mautrixConfigURL: String? {
        get {
            UserDefaults.standard.string(forKey: BLConfigURLKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: BLConfigURLKey)
                return
            }
            
            UserDefaults.standard.set(newValue, forKey: BLConfigURLKey)
        }
    }
    
    public var mautrixCWD: String {
        get {
            UserDefaults.standard.string(forKey: BLCWDKey) ?? "~/tmp/mautrix-imessage".expandingTildeInPath
        }
        set {
            UserDefaults.standard.set(newValue, forKey: BLCWDKey)
        }
    }
}
