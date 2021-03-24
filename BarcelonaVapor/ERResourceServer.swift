//
//  ERResourceServer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/22/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreUI
import CoreImage
import LinkPresentation
import Vapor

#if canImport(CoreServices)
import CoreServices
#endif

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension String: Error {}

private enum AssetsFormat: String, CaseIterable {
    case localSocialUI = "~/Library/Application Support/MyMessage/Assets.SocialUI.car"
    case localChatKit = "~/Library/Application Support/MyMessage/Assets.ChatKit.car"
    case localChatKitRetina = "~/Library/Application Support/MyMessage/Assets.ChatKitRetina.car"
    case ios = "/System/Library/PrivateFrameworks/ChatKit.framework/Assets.car"
    case iosMac = "/System/iOSSupport/System/Library/PrivateFrameworks/ChatKit.framework/Resources/Assets.car"
    case mac = "/System/Library/PrivateFrameworks/SocialUI.framework/Resources/Assets.car"
    
    var url: URL {
        URL(fileURLWithPath: NSString(string: self.rawValue).expandingTildeInPath)
    }
    
    var mode: AssetsMode {
        switch self {
        case .ios:
            fallthrough
        case .localChatKitRetina:
            return .ChatKitRetina
        case .iosMac:
            fallthrough
        case .localChatKit:
            return .ChatKit
        case .mac:
            fallthrough
        case .localSocialUI:
            return .SocialUI
        }
    }
    
    static var hostAssetFormat: AssetsFormat? {
        return allCases.first(where: {
            FileManager.default.fileExists(atPath: $0.url.path)
        })
    }
}

internal enum AssetsMode: String, Content {
    case SocialUI
    case ChatKit
    case ChatKitRetina
}

private struct AssetsModeRepresentation: Content {
    var mode: AssetsMode
}

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, kUTTypePNG, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

private struct CatalogListing: Content {
    var items: [String]
}

private let SocialUIBindings = [
    "bubble-tail": "bubble-local",
    "bubble-notail": "bubble-local-notail",
    "bubble-stroke-tail": "attachment-local",
    "bubble-stroke-notail": "attachment-local-notail",
    "send-button": "effect-picker-button",
    "ack-bubble": "Acknowledgment-Balloon",
    "ack-double-bubble": "Acknowledgment-Stack",
    "ack-middle": "Acknowledgment-Stack-Etc-From-Me",
    "ack-stack": "Acknowledgment-Stack-Etc-Not-From-Me",
    "ack-heart": "Ack-Balloon-Heart",
    "ack-thumbs-up": "Ack-Balloon-ThumbsUp",
    "ack-thumbs-down": "Ack-Balloon-ThumbsDown",
    "ack-emphasize": "Ack-Balloon-Exclamation",
    "ack-question": "Ack-Balloon-QuestionMark",
    "ack-haha-ar": "Ack-Balloon-Haha_AR",
    "ack-haha-el": "Ack-Balloon-Haha_EL",
    "ack-haha-en": "Ack-Balloon-Haha_EN",
    "ack-haha-es": "Ack-Balloon-Haha_ES",
    "ack-haha-he": "Ack-Balloon-Haha_HE",
    "ack-haha-hi": "Ack-Balloon-Haha_HI",
    "ack-haha-it": "Ack-Balloon-Haha_IT",
    "ack-haha-ja": "Ack-Balloon-Haha_JA",
    "ack-haha-ko": "Ack-Balloon-Haha_KO",
    "ack-haha-th": "Ack-Balloon-Haha_TH",
    "ack-haha-zh": "Ack-Balloon-Haha_ZH",
    "replay": "replay-icon",
    "icloud": "icloud",
    "video-play": "Video-play-button",
    "recorded-audio-template": "RecordAudioTemplate"
]

private let ChatKitBindings = [
    "bubble-tail": "bubble",
    "bubble-notail": "bubble-tailless",
    "bubble-stroke-tail": "bubble-stroked",
    "bubble-stroke-notail": "bubble-stroked-tailless",
    "send-button": "Impact-Send",
    "ack-bubble": "AcknowledgmentTop",
    "ack-double-bubble": "AcknowledgmentStack-2",
    "ack-middle": "AcknowledgmentMiddle",
    "ack-stack": "AcknowledgmentStack-3",
    "ack-heart": "Acknowledgments-Menu-Heart",
    "ack-thumbs-up": "Acknowledgments-Menu-ThumbsUp",
    "ack-thumbs-down": "Acknowledgments-Menu-ThumbsDown",
    "ack-emphasize": "Acknowledgments-Menu-Exclamation",
    "ack-question": "Acknowledgments-Menu-QuestionMark",
    "ack-haha-ar": "Acknowledgments-Menu-HAHA-ARA",
    "ack-haha-el": "Acknowledgments-Menu-HAHA-CYR",
    "ack-haha-en": "Polling-HAHA-ENG-Large",
    "ack-haha-es": "Acknowledgments-Menu-HAHA-ESP",
    "ack-haha-he": "Acknowledgments-Menu-HAHA-HEB",
    "ack-haha-hi": "Acknowledgments-Menu-HAHA-HIN",
    "ack-haha-it": "Acknowledgments-Menu-HAHA-ITA",
    "ack-haha-ja": "Acknowledgments-Menu-HAHA-JPN",
    "ack-haha-ko": "Acknowledgments-Menu-HAHA-KOR",
    "ack-haha-th": "Acknowledgments-Menu-HAHA-THA",
    "ack-haha-zh": "Acknowledgments-Menu-HAHA-CHN",
    "replay": "Replay",
    "icloud": "iCloudIcon-40",
    "video-play": "ActionMenuPlay",
    "recorded-audio-template": "AudioMessageWaveform"
]

private let CatalogBindings: [AssetsFormat: [String: String]] = [
    .mac: SocialUIBindings,
    .ios: ChatKitBindings,
    .iosMac: ChatKitBindings,
    .localChatKit: ChatKitBindings,
    .localSocialUI: SocialUIBindings,
    .localChatKitRetina: ChatKitBindings
]

internal class ERResourceServer {
    private let assetsFormat: AssetsFormat
    private let assetsURL: URL
    private let catalog: CUICatalog
    
    public init(_ app: Application) throws {
        let resources = app.grouped("resources")
        
        guard let assetsFormat = AssetsFormat.hostAssetFormat else {
            throw "Unable to resolve assets format"
        }
        
        self.assetsFormat = assetsFormat
        assetsURL = assetsFormat.url
        
        catalog = try CUICatalog(url: assetsURL)
        
        resources.get("catalog") { req -> CatalogListing in
            return CatalogListing(items: self.imageNames)
        }
        
        resources.get("mode") { req -> AssetsModeRepresentation in
            return AssetsModeRepresentation(mode: self.assetsFormat.mode)
        }
        
        resources.grouped("symbol").get(":id") { req -> EventLoopFuture<Response> in
//            guard let symbolName = req.parameters.get("id") else {
//                return HTTPStatus.badRequest.encodeResponse(for: req)
//            }
//
//            #if canImport(AppKit)
//            let image = NSImage()
//            #elseif canImport(UIKit)
//            #endif
            
            return HTTPStatus.notFound.encodeResponse(for: req)
        }
        
        resources.grouped("raw").get(":name") { req -> EventLoopFuture<Response> in
            guard let name = req.parameters.get("name") else {
                return HTTPStatus.notFound.encodeResponse(for: req)
            }
            
            return self.respondWithImage(name, req: req)
        }
        
        resources.get("lp-default") { req -> EventLoopFuture<HTTPStatus> in
            if let resources = NSClassFromString("LPResources") as? NSObject.Type, let icon = resources.perform(#selector(LPResources.safariIcon)) {
                print(icon)
            }
            
            return req.eventLoop.makeSucceededFuture(HTTPStatus.notFound)
        }
        
        resources.get(":name") { req -> EventLoopFuture<Response> in
            guard let unresolvedName = req.parameters.get("name") else {
                return HTTPStatus.badRequest.encodeResponse(for: req)
            }
            
            guard let resolvedName = self.bindings[unresolvedName] else {
                return HTTPStatus.notFound.encodeResponse(for: req)
            }
            
            return self.respondWithImage(resolvedName, req: req)
        }
    }
    
    private func respondWithImage(_ name: String, req: Request) -> EventLoopFuture<Response> {
        guard var image = self.cgImageWithName(name, scale: Double((try? req.query.get(Int.self, at: "scale")) ?? 1)) else {
            return HTTPStatus.notFound.encodeResponse(for: req)
        }
        
        if (try? req.query.get(Int.self, at: "flip") == 1) ?? false {
            let flipped = CIImage(cgImage: image).transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            let context = CIContext(options: nil)
            if let flippedCGImage = context.createCGImage(flipped, from: flipped.extent) {
                image = flippedCGImage
            }
        }

        guard let data = image.png else {
            return HTTPStatus.internalServerError.encodeResponse(for: req)
        }

        let fileResponse = Response.init(status: .ok, version: req.version, headers: .init([
            ("content-type", "image/png"),
            ("content-length", String(data.count)),
            ("cache-control", "public, max-age=3600")
        ]), body: .init(data: data))

        return req.eventLoop.makeSucceededFuture(fileResponse)
    }
    
    private func cgImageWithName(_ name: String, scale: Double = 1.0, horizontalFlip: Bool = false) -> CGImage? {
        guard let images = catalog.images(withName: name)?.sorted(by: {
            $0.scale < $1.scale
        }) else {
            return nil
        }
        
        var imageScale = scale;
        
        if (images.first?.scale ?? 0) > imageScale {
            imageScale = images.first?.scale ?? 0
        }
        
        guard let image = catalog.image(withName: name, scaleFactor: imageScale), let ptr = image.image() else {
            return nil
        }
        
        return ptr.takeUnretainedValue()
    }
    
    private var bindings: [String: String] {
        return CatalogBindings[self.assetsFormat] ?? [:]
    }
    
    private var imageNames: [String] {
        catalog.allImageNames()
    }
}
