//
//  PluginChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation
import IMCore
import DigitalTouchShared
import SpriteKit
import os.log

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

private func withLightAppearance<T>(_ closure: () throws -> T) rethrows -> T {
    #if canImport(AppKit)
    let previousAppearance = NSAppearance.current
    NSAppearance.current = NSAppearance.init(named: .aqua)
    defer {
        NSAppearance.current = previousAppearance
    }
    #endif
    
    return try closure()
}

private let frameProperties = [
    kCGImagePropertyPNGDictionary as String: [
        kCGImagePropertyAPNGLoopCount as String: 0
    ]
] as CFDictionary

private func withETCGDestination(atURL url: URL, count: Int = 0, callback: (CGImageDestination) -> ()) {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, count, frameProperties as CFDictionary) else {
        return
    }
    
    callback(destination)
    
    CGImageDestinationFinalize(destination)
}

private func ETMessageRenderRect() -> CGRect {
    .init(x: 0, y: 0, width: ETMessageRenderBufferWidth, height: ETMessageRenderBufferHeight)
}

private let ETSpriteFPS = 60.0

private let ETParseLog = OSLog(subsystem: "com.ericrabil.imessage-rest", category: "ETParseLog")

public struct PluginChatItem: ChatItemRepresentation, ChatItemAcknowledgable {
    init(_ item: IMTranscriptPluginChatItem, chatID: String?) {
        bundleID = item.dataSource.bundleID
        attachments = item.attachments
        
        var insertPayload: Bool = true
        
        switch bundleID {
        case "com.apple.DigitalTouchBalloonProvider":
            if let dataSource = item.dataSource, let messages = dataSource.perform(Selector(("createSessionMessages")))?.takeUnretainedValue() as? Array<ETMessage>, let message = messages.first {
                
                digitalTouch = DigitalTouchMessage(message: message)
                switch (message) {
                case let message as ETSketchMessage:
                    withETCGDestination(atURL: URL(fileURLWithPath: "/Users/ericrabil/penis.png")) {
                        let sketchView = ETGLSketchView(frame: ETMessageRenderRect())
                        sketchView.messageData = message
                        sketchView.sample(into: $0, frameProperties: [:] as CFDictionary, usingAlpha: true)
                    }
                    
                    break
                case is ETTapMessage:
                    fallthrough
                case is ETKissMessage:
                    fallthrough
                case is ETAngerMessage:
                    fallthrough
                case is ETHeartbeatMessage:
                    let duration = Int(message.messageDuration * ETSpriteFPS)
                    withETCGDestination(atURL: URL(fileURLWithPath: "/Users/ericrabil/dts-\(item.id).png"), count: duration) { destination in
                        let rect = ETMessageRenderRect()
                        
                        message.isRenderingOffscreen = true
                        
                        let scene = SKScene(size: rect.size)
                        scene.backgroundColor = .black
                        scene.anchorPoint = .init(x: 0.5, y: 0.5)
                        
                        let view = SKView(frame: rect as NSRect)
                        view.presentScene(scene)
                        view.isPaused = false
                        view.shouldCullNonVisibleNodes = false
                        
                        scene.perform(Selector("_update:"), with: 0.0)
                        
                        message.display(inScene: scene)
                        
                        var passes = 0
                        
                        os_log("Rendering ETSpriteMessage with %d frames and duration %.2f", log: ETParseLog, duration, message.messageDuration)
                        
                        repeat {
                            view.isPaused = false
                            
                            let pos = Double(passes) / ETSpriteFPS
                            
                            scene.perform(Selector("_update:"), with: pos)
                            
                            view.isPaused = true
                            
                            if let cgImage = view.texture(from: scene)?.cgImage() {
                                CGImageDestinationAddImage(destination, cgImage, frameProperties)
                            }
                            
                            passes += 1
                        } while (passes < duration)
                    }
                default:
                    break
                }
            }
            insertPayload = false
            break
        case "com.apple.messages.URLBalloonProvider":
            withLightAppearance {
                if let dataSource = item.dataSource, let metadata = dataSource.value(forKey: "richLinkMetadata") as? LPLinkMetadata, let richLink = RichLinkRepresentation(metadata: metadata, attachments: item.internalAttachments) {
                    self.richLink = richLink
                    insertPayload = false
                }
            }
            break
        default:
            break
        }
        
        if bundleID.starts(with: "com.apple.messages.MSMessageExtensionBalloonPlugin"), let payloadData = item.dataSource?.payload {
            `extension` = MessageExtensionsData(payloadData)
            insertPayload = false
        }
        
        if insertPayload {
            payload = item.dataSource.payload?.base64EncodedString()
        }
        
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var digitalTouch: DigitalTouchMessage?
    public var richLink: RichLinkRepresentation?
    public var `extension`: MessageExtensionsData?
    public var payload: String?
    public var bundleID: String
    public var attachments: [Attachment]
    public var acknowledgments: [AcknowledgmentChatItem]?
}
