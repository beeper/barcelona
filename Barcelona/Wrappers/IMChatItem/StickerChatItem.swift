//
//  AssociatedStickerChatItem.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/25/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities
import IMCore

private let IMStickerUserInfoStickerGUIDKey = "sid"
private let IMStickerUserInfoStickerPackGUIDKey = "pid"
private let IMStickerUserInfoStickerHashKey = "shash"
private let IMStickerUserInfoStickerRecipeKey = "srecipe"
private let IMStickerUserInfoStickerBIDKey = "sbid"
private let IMStickerUserInfoTranscodedStickerHashKey = "sthash"
private let IMStickerUserInfoLayoutIntentKey = "sli"
private let IMStickerUserInfoAssociatedLayoutIntentKey = "sai"
private let IMStickerUserInfoParentPreviewWidthKey = "spw"
private let IMStickerUserInfoXScalarKey = "sxs"
private let IMStickerUserInfoYScalarKey = "sys"
private let IMStickerUserInfoScaleKey = "ssa"
private let IMStickerUserInfoRotationKey = "sro"
private let IMStickerUserInfoTranscodedScaleKey = "tssa"

public struct StickerInformation: Codable, Hashable {
    public var stickerID: String
    public var stickerPackID: String
    public var stickerHash: String
    public var stickerRecipe: String?
    public var bid: String?
    public var transcodedStickerHash: String?
    public var layoutIntent: Int?
    public var associatedLayoutIntent: Int?
    public var parentPreviewWidth: Double?
    public var xScalar: Double?
    public var yScalar: Double?
    public var scale: Double?
    public var rotation: Double?
    public var transcodedScale: Double?
    
    public init?(_ info: [AnyHashable: Any?]) {
        guard let stickerGUID = info[IMStickerUserInfoStickerGUIDKey] as? String, let stickerPackGUID = info[IMStickerUserInfoStickerPackGUIDKey] as? String, let stickerHash = info[IMStickerUserInfoStickerHashKey] as? String else {
            return nil
        }
        
        self.stickerID = stickerGUID
        self.stickerPackID = stickerPackGUID
        self.stickerHash = stickerHash
        
        if let rawLayoutIntent = info[IMStickerUserInfoLayoutIntentKey] as? String, let rawAssociatedLayoutIntent = info[IMStickerUserInfoAssociatedLayoutIntentKey] as? String, let rawParentPreviewWidth = info[IMStickerUserInfoParentPreviewWidthKey] as? String, let rawXScalar = info[IMStickerUserInfoXScalarKey] as? String, let rawYScalar = info[IMStickerUserInfoYScalarKey] as? String, let rawScale = info[IMStickerUserInfoScaleKey] as? String, let rawRotation = info[IMStickerUserInfoRotationKey] as? String, let layoutIntent = Int(rawLayoutIntent), let associatedLayoutIntent = Int(rawAssociatedLayoutIntent), let parentPreviewWidth = Double(rawParentPreviewWidth), let xScalar = Double(rawXScalar), let yScalar = Double(rawYScalar), let scale = Double(rawScale), let rotation = Double(rawRotation) {
            self.layoutIntent = layoutIntent
            self.associatedLayoutIntent = associatedLayoutIntent
            self.parentPreviewWidth = parentPreviewWidth
            self.xScalar = xScalar
            self.yScalar = yScalar
            self.scale = scale
            self.rotation = rotation
        }
        
        if let stickerRecipe = info[IMStickerUserInfoStickerRecipeKey] as? String {
            self.stickerRecipe = stickerRecipe
        }
        
        if let bid = info[IMStickerUserInfoStickerBIDKey] as? String {
            self.bid = bid
        }
        
        if let transcodedStickerHash = info[IMStickerUserInfoTranscodedStickerHashKey] as? String {
            self.transcodedStickerHash = transcodedStickerHash
        }
        
        if let rawTranscodedScale = info[IMStickerUserInfoTranscodedScaleKey] as? String, let transcodedScale = Double(rawTranscodedScale) {
            self.transcodedScale = transcodedScale
        }
    }
}

public struct StickerChatItem: ChatItemAssociable, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMAssociatedStickerChatItem.self]
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMAssociatedStickerChatItem, chatID: context.chatID)
    }
    
    init(_ item: IMAssociatedStickerChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        associatedID = item.associatedMessageGUID
        sender = item.sender.id
        
        if let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: item.transferGUID) {
            self.attachment = Attachment(transfer)
        }
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var associatedID: String
    public var attachment: Attachment?
    public var sender: String?
    
    public var type: ChatItemType {
        .sticker
    }
}
