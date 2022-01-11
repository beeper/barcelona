//
//  CBFeatureFlags.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/11/22.
//

import Foundation

public let CBFeatureFlags = (
    permitInvalidAudioMessages: ProcessInfo.processInfo.arguments.contains("--disable-amr-validation"),
    performAMRTranscoding: ProcessInfo.processInfo.arguments.contains("--enable-amr-transcoding")
)
