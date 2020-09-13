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

struct StickerInformation: Codable {
    var stickerID: String
    var stickerPackID: String
    var stickerHash: String
    var stickerRecipe: String?
    var bid: String?
    var transcodedStickerHash: String?
    var layoutIntent: Int
    var associatedLayoutIntent: Int
    var parentPreviewWidth: Double
    var xScalar: Double
    var yScalar: Double
    var scale: Double
    var rotation: Double
    var transcodedScale: Double?
    
    fileprivate init?(_ info: [String: Any?]) {
        guard let stickerGUID = info[IMStickerUserInfoStickerGUIDKey] as? String, let stickerPackGUID = info[IMStickerUserInfoStickerPackGUIDKey] as? String, let stickerHash = info[IMStickerUserInfoStickerHashKey] as? String, let rawLayoutIntent = info[IMStickerUserInfoLayoutIntentKey] as? String, let rawAssociatedLayoutIntent = info[IMStickerUserInfoAssociatedLayoutIntentKey] as? String, let rawParentPreviewWidth = info[IMStickerUserInfoParentPreviewWidthKey] as? String, let rawXScalar = info[IMStickerUserInfoXScalarKey] as? String, let rawYScalar = info[IMStickerUserInfoYScalarKey] as? String, let rawScale = info[IMStickerUserInfoScaleKey] as? String, let rawRotation = info[IMStickerUserInfoRotationKey] as? String else {
            return nil
        }
        
        self.stickerID = stickerGUID
        self.stickerPackID = stickerPackGUID
        self.stickerHash = stickerHash
        
        guard let layoutIntent = Int(rawLayoutIntent), let associatedLayoutIntent = Int(rawAssociatedLayoutIntent), let parentPreviewWidth = Double(rawParentPreviewWidth), let xScalar = Double(rawXScalar), let yScalar = Double(rawYScalar), let scale = Double(rawScale), let rotation = Double(rawRotation) else {
            return nil
        }
        
        self.layoutIntent = layoutIntent
        self.associatedLayoutIntent = associatedLayoutIntent
        self.parentPreviewWidth = parentPreviewWidth
        self.xScalar = xScalar
        self.yScalar = yScalar
        self.scale = scale
        self.rotation = rotation
        
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

struct StickerChatItem: AssociatedChatItemRepresentation {
    init(_ item: IMAssociatedStickerChatItem, chatID: String?) {
        associatedID = item.associatedMessageGUID
        
        if let transfer = IMFileTransferCenter.sharedInstance()?.transfer(forGUID: item.transferGUID) {
            self.attachment = Attachment(transfer)
            
            if transfer.isSticker, let userInfo = transfer.stickerUserInfo {
                if let sticker = StickerInformation(userInfo as! [String: Any]) {
                    self.sticker = sticker
                } else {
                    print("failed to parse sticker info at \(userInfo)")
                }
            }
        }
        
        load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var associatedID: String
    var attachment: Attachment?
    var sticker: StickerInformation?
}
