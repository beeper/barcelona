//
//  IncomingMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
@_spi(matrix) import Barcelona
import IMCore
import Swog

internal extension Chat {
    var blChatGUID: String {
        imChat.blChatGUID
    }
}

internal extension IMChat {
    var blFacingService: String {
        if MXFeatureFlags.shared.mergedChats {
            return "iMessage"
        } else {
            return account.serviceName
        }
    }
    
    var blChatGUID: String {
        "\(blFacingService);\(isGroup ? "+" : "-");\(id)"
    }
    
    var ipcGUID: PBGUID {
        .with {
            $0.service = account.serviceName
            $0.isGroup = isGroup
            $0.localID = chatIdentifier
        }
    }
}

private extension Message {
    var blSenderGUID: String? {
        guard let sender = sender, !fromMe else {
            return nil
        }
        
        return "\(service.rawValue);\(isGroup ? "+" : "-");\(sender)"
    }

    var ipcSenderGUID: PBGUID? {
        guard let sender = sender, !fromMe else {
            return nil
        }

        return .with {
            $0.service = self.service.rawValue
            $0.isGroup = false
            $0.localID = sender
        }
    }
    
    var blChatGUID: String {
        imChat.blChatGUID
    }
    
    var ipcChatGUID: PBGUID {
        .with {
            $0.service = self.service.rawValue
            $0.isGroup = self.isGroup
            $0.localID = self.chatID
        }
    }

    var isGroup: Bool {
        IMChat.resolve(withIdentifier: chatID)!.isGroup
    }
    
    var textContent: String {
        items.map(\.item).reduce(into: [String]()) { text, item in
            switch item {
            case let item as TextChatItem:
                text.append(item.text)
            case let item as PluginChatItem:
                if let fallbackText = item.fallback?.text {
                    text.append(fallbackText)
                }
            default:
                break
            }
        }.joined(separator: " ")
    }
}

private extension ParticipantChangeItem {
    func blTargetGUID(on service: String, isGroup: Bool) -> String? {
        guard let targetID = targetID else {
            return nil
        }
        
        return "\(service);\(isGroup ? "+" : "-");\(targetID)"
    }

    func ipcTargetGUID(on service: String, isGroup: Bool) -> PBGUID? {
        guard let targetID = targetID else {
            return nil
        }
        return .with { guid in
            guid.service = service
            guid.isGroup = isGroup
            guid.localID = targetID
        }
    }
}

import BarcelonaMautrixIPCProtobuf

public typealias BLMessage = PBMessage

func ReadEncodedGUIDPart(_ guid: String) -> Int? {
    guard let colon = guid.firstIndex(of: ":") else {
        return nil
    }
    let afterColon = guid.index(after: colon)
    guard let slash = guid[afterColon...].firstIndex(of: ":") else {
        return nil
    }
    return Int(guid[afterColon..<slash])
}

extension PBItem {
    public init?(chatItem: ChatItem) {
        if let item = Self.from(chatItem: chatItem) {
            self = item
        } else {
            return nil
        }
    }
    
    public static func from(chatItem: ChatItem) -> PBItem? {
        switch chatItem {
        case let text as TextChatItem:
            return .with { item in
                item.guid = text.id
                item.text = .with { item in
                    item.text = text.text
                    text.subject.oassign(to: &item.subject)
                }
            }
        case let attachment as AttachmentChatItem:
            return .with { item in
                item.guid = attachment.id
                item.attachment = .with { item in
                    attachment.metadata.flatMap(PBAttachment.init(_:)).oassign(to: &item.attachment)
                }
            }
        case let typing as TypingItem:
            return .with { item in
                item.guid = typing.id
                item.typing = .with { item in
                    item.typing = true
                }
            }
        case let plugin as PluginChatItem:
            return .with { item in
                item.guid = plugin.id
                item.plugin = .with { item in
                    item.attachments = plugin.attachments.compactMap(PBAttachment.init(_:))
                    var metadata: RichLinkMetadata?
                    if let richLink = plugin.richLink {
                        metadata = richLink
                    } else if let extensionData = plugin.extension {
                        metadata = RichLinkMetadata(extensionData: extensionData, attachments: plugin.attachments, fallbackText: &item.fallbackText)
                    }
                    if metadata?.usableForMatrix == false {
                        metadata = nil
                    }
                    (metadata?.pb).oassign(to: &item.richLink)
                }
            }
        case let groupName as GroupTitleChangeItem:
            return .with { item in
                item.guid = groupName.id
                item.groupNameChange = .with { item in
                    groupName.title.oassign(to: &item.title)
                }
            }
        case let participantChange as ParticipantChangeItem:
            return .with { item in
                item.guid = participantChange.id
                item.groupParticipantChange = .with { item in
                    PBGroupActionType(rawValue: Int(participantChange.changeType)).oassign(to: &item.action)
                    participantChange.targetID.oassign(to: &item.target)
                    participantChange.initiatorID.oassign(to: &item.initiator)
                }
            }
        case let action as GroupActionItem:
            guard action.actionType.rawValue == 3 else {
                return nil
            }
            return .with { item in
                item.guid = action.id
                item.groupAvatarChange = .with { item in
                    let transferGUID = String(format: "%@%@%lu%@%@", "at", "_", 0, "_", action.id)
                    if let transfer = PBAttachment(guid: transferGUID) {
                        item.action = .groupActionAdd
                        item.newAvatar = transfer
                    } else {
                        item.action = .groupActionRemove
                    }
                }
            }
        case let tapback as AcknowledgmentChatItem:
            return .with { item in
                item.guid = tapback.id
                item.tapback = .with { item in
                    item.tapback = .with { tb in
                        PBTapbackType(rawValue: Int(tapback.acknowledgmentType)).oassign(to: &tb.type)
                        tb.target = tapback.associatedID
                    }
                }
            }
        case let unknown:
            return .with { item in
                item.guid = unknown.id
                item.phantom = .with { item in
                    item.typeString = String(describing: type(of: item))
                    item.debugDescription_p = item.debugDescription
                }
            }
        }
    }
}

extension PBMessage {
    public init(message: Message) {
        self = .from(message: message)
    }

    public static func from(message: Message) -> PBMessage {
        .with { pb in
            pb.guid = message.id
            pb.time = .init(timeIntervalSince1970: message.time)
//            message.messageSubject.oassign(to: &pb.subject)
            pb.chatGuid = message.ipcChatGUID
            message.ipcSenderGUID.oassign(to: &pb.sender)
            pb.isFromMe = message.isFromMe
            pb.isRead = message.isRead
            pb.isDelivered = message.isDelivered
            pb.isSent = message.isSent
            pb.isAudioMessage = message.isAudioMessage
            message.threadOriginator.map { originator in
                pb.threadTarget = .with {
                    $0.guid = originator
                    $0.part = Int64(message.threadOriginatorPart ?? 0)
                }
            }
            (message.metadata?.pb).oassign(to: &pb.messageMetadata)
            pb.correlations = .with {
                (message.imChat?.correlationIdentifier).oassign(to: &$0.chat)
                message.senderCorrelationID.oassign(to: &$0.sender)
            }
            pb.service = message.service.rawValue
            pb.items = message.items.compactMap { chatItem -> PBItem? in
                switch chatItem.item {
                case let text as TextChatItem:
                    return .with { item in
                        item.guid = text.id
                        item.text = .with { item in
                            item.text = text.text
                            text.subject.oassign(to: &item.subject)
                        }
                    }
                case let attachment as AttachmentChatItem:
                    return .with { item in
                        item.guid = attachment.id
                        item.attachment = .with { item in
                            attachment.metadata.flatMap(PBAttachment.init(_:)).oassign(to: &item.attachment)
                        }
                    }
                case let typing as TypingItem:
                    return .with { item in
                        item.guid = typing.id
                        item.typing = .with { item in
                            item.typing = true
                        }
                    }
                case let plugin as PluginChatItem:
                    return .with { item in
                        item.guid = plugin.id
                        item.plugin = .with { item in
                            item.attachments = plugin.attachments.compactMap(PBAttachment.init(_:))
                            var metadata: RichLinkMetadata?
                            if let richLink = plugin.richLink {
                                metadata = richLink
                            } else if let extensionData = plugin.extension {
                                metadata = RichLinkMetadata(extensionData: extensionData, attachments: plugin.attachments, fallbackText: &item.fallbackText)
                            }
                            if metadata?.usableForMatrix == false {
                                metadata = nil
                            }
                            (metadata?.pb).oassign(to: &item.richLink)
                        }
                    }
                case let groupName as GroupTitleChangeItem:
                    return .with { item in
                        item.guid = groupName.id
                        item.groupNameChange = .with { item in
                            groupName.title.oassign(to: &item.title)
                        }
                    }
                case let participantChange as ParticipantChangeItem:
                    return .with { item in
                        item.guid = participantChange.id
                        item.groupParticipantChange = .with { item in
                            PBGroupActionType(rawValue: Int(participantChange.changeType)).oassign(to: &item.action)
                            participantChange.targetID.oassign(to: &item.target)
                            participantChange.initiatorID.oassign(to: &item.initiator)
                        }
                    }
                case let action as GroupActionItem:
                    guard action.actionType.rawValue == 3 else {
                        return nil
                    }
                    return .with { item in
                        item.guid = action.id
                        item.groupAvatarChange = .with { item in
                            let transferGUID = String(format: "%@%@%lu%@%@", "at", "_", 0, "_", action.id)
                            if let transfer = PBAttachment(guid: transferGUID) {
                                item.action = .groupActionAdd
                                item.newAvatar = transfer
                            } else {
                                item.action = .groupActionRemove
                            }
                        }
                    }
                case let tapback as AcknowledgmentChatItem:
                    return .with { item in
                        item.guid = tapback.id
                        item.tapback = .with { item in
                            item.tapback = .with { tb in
                                PBTapbackType(rawValue: Int(tapback.acknowledgmentType)).oassign(to: &tb.type)
                                tb.target = tapback.associatedID
                            }
                        }
                    }
                case let unknown:
                    return .with { item in
                        item.guid = unknown.id
                        item.phantom = .with { item in
                            item.typeString = String(describing: type(of: item))
                            item.debugDescription_p = item.debugDescription
                        }
                    }
                }
            }
        }
    }
    
    // public static func from(message: Message) -> PBMessage {
    //     .with { [message] `self` in
    //         self.guid = message.id
    //         self.time = .init(timeIntervalSince1970: message.time / 1000)
    //         message.subject.map {
    //             self.subject = $0
    //         }
    //         self.text = message.textContent
    //         self.chatGuid = message.ipcChatGUID
    //         message.ipcSenderGUID.map {
    //             self.sender = $0
    //         }
    //         self.service = message.service.rawValue
    //         self.isFromMe = message.fromMe
    //         message.threadOriginator.map { threadOriginator in
    //             self.threadTarget = .with { target in
    //                 target.guid = threadOriginator
    //                 target.part = message.threadOriginatorPart.map(Int64.init(_:)) ?? 0
    //             }
    //         }
    //         self.attachments = message.fileTransferIDs.compactMap {
    //             PBAttachment(guid: $0)
    //         }
    //         self.isAudioMessage = message.isAudioMessage
    //         self.isRead = message.isReadByMe
    //         message.metadata.map(\.pb).oassign(to: &self.messageMetadata)
    //         self.correlations = .with { correlations in
    //             message.imChat?.correlationIdentifier.map {
    //                 correlations.chat = $0
    //             }
    //             message.senderCorrelationID.map {
    //                 correlations.sender = $0
    //             }
    //         }
    //         for item in message.items {
    //             switch item.item {
    //             case let changeItem as GroupTitleChangeItem:
    //                 changeItem.title.map {
    //                     self.newGroupName = $0
    //                 }
    //                 self.itemType = .name
    //             case let action as ParticipantChangeItem:
    //                 self.groupActionType = action.changeType == 0 ? .groupActionAdd : .groupActionRemove
    //                 self.itemType = .member
    //                 action.ipcTargetGUID(on: self.service, isGroup: message.imChat.isGroup).map {
    //                     self.target = $0
    //                 }
    //             case let item as GroupActionItem:
    //                 // self.groupActionType = item.actionType == . ? .groupActionAdd : .groupActionRemove
    //                 // (item.actionType == .changePhoto ? .avatar : item.actionType == .leave ? .member : nil).oassign(to: &itemType)
    //                 // self.group_action_type = Int(item.actionType.rawValue)
    //                 // self.item_type = IMItemType.groupAction.rawValue
    //                 break
    //             case let acknowledgment as AcknowledgmentChatItem:
    //                 guard let parsedID = CBMessageItemIdentifierData(rawValue: acknowledgment.associatedID) else {
    //                     CLFault("BLMessage", "Failed to parse associatedID %@", acknowledgment.associatedID)
    //                     continue
    //                 }
    //                 self.tapback = .with { tapback in
    //                     tapback.target = .with { target in
    //                         target.guid = acknowledgment.associatedID
    //                         target.part = parsedID.part.map(Int64.init(_:)) ?? 0
    //                     }
    //                     PBTapbackType(rawValue: Int(acknowledgment.acknowledgmentType)).map {
    //                         tapback.type = $0
    //                     }
    //                 }
    //             case let plugin as PluginChatItem:
//                     self.attachments = message.fileTransferIDs.filter { id in
//                         !plugin.attachments.map(\.id).contains(id)
//                     }.compactMap {
//                         BLAttachment(guid: $0)
//                     }
//                     var metadata: RichLinkMetadata?
//                     if let richLink = plugin.richLink {
//                         metadata = richLink
//                     } else if let extensionData = plugin.extension {
//                         metadata = RichLinkMetadata(extensionData: extensionData, attachments: plugin.attachments, fallbackText: &self.text)
//                     }
//                     if metadata?.usableForMatrix == false {
//                         metadata = nil
//                     }
//                     (metadata?.pb).oassign(to: &self.richLink)
    //             default:
    //                 continue
    //             }
    //         }
    //     }
    // }
    
    public init(message: Message, phantoms: inout [PhantomChatItem]) {
        self.init(message: message)
        
        for item in message.items {
            if let phantom = item.item as? PhantomChatItem {
                phantoms.append(phantom)
            }
        }
    }
    
    public static func < (left: PBMessage, right: PBMessage) -> Bool {
        left.time.date < right.time.date
    }
    
    public static func > (left: PBMessage, right: PBMessage) -> Bool {
        left.time.date < right.time.date
    }
    
    public static func <= (left: PBMessage, right: PBMessage) -> Bool {
        left.time.date <= right.time.date
    }
    
    public static func >= (left: PBMessage, right: PBMessage) -> Bool {
        left.time.date >= right.time.date
    }
}

public extension RichLinkMetadata {
    var pb: PBRichLink {
        .with { richLink in
            (originalURL?.absoluteString).oassign(to: &richLink.originalURL)
            (URL?.absoluteString).oassign(to: &richLink.url)
            title.oassign(to: &richLink.title)
            summary.oassign(to: &richLink.summary)
            selectedText.oassign(to: &richLink.selectedText)
            siteName.oassign(to: &richLink.siteName)
            (relatedURL?.absoluteString).oassign(to: &richLink.relatedURL)
            creator.oassign(to: &richLink.creator)
            creatorFacebookProfile.oassign(to: &richLink.creatorFacebookProfile)
            creatorTwitterUsername.oassign(to: &richLink.creatorTwitterUsername)
            itemType.oassign(to: &richLink.itemType)
            (icon?.pb).oassign(to: &richLink.icon)
            (image?.pb).oassign(to: &richLink.image)
            (video?.pb).oassign(to: &richLink.video)
            (audio?.pb).oassign(to: &richLink.audio)
            (images?.map(\.pb)).oassign(to: &richLink.images)
            (videos?.map(\.pb)).oassign(to: &richLink.videos)
            (streamingVideos?.map(\.pb)).oassign(to: &richLink.streamingVideos)
            (audios?.map(\.pb)).oassign(to: &richLink.audios)
        }
    }
}

public extension RichLinkMetadata.RichLinkAsset.Size {
    var pb: PBRichLinkAssetSize {
        .with { size in
            size.width = Int64(size.width)
            size.height = Int64(size.height)
        }
    }
}

public extension RichLinkMetadata.RichLinkAsset.Source {
    var pb: PBRichLinkAssetSource {
        .with { source in
            switch self {
            case .data(let data):
                source.data = data
            case .url(let url):
                source.url = url.absoluteString
            }
        }
    }
}

public extension RichLinkMetadata.RichLinkVideoAsset {
    var pb: PBRichLinkVideoAsset {
        .with { asset in
            hasAudio.oassign(to: &asset.hasAudio_p)
            (youTubeURL?.absoluteString).oassign(to: &asset.youTubeURL)
            (streamingURL?.absoluteString).oassign(to: &asset.streamingURL)
            asset.asset = self.asset.pb
        }
    }
}

public extension RichLinkMetadata.RichLinkAsset {
    var pb: PBRichLinkAsset {
        .with { asset in
            mimeType.oassign(to: &asset.mimeType)
            accessibilityText.oassign(to: &asset.accessibilityText)
            (source?.pb).oassign(to: &asset.source)
            (originalURL?.absoluteString).oassign(to: &asset.originalURL)
            (size?.pb).oassign(to: &asset.size)
        }
    }
}

extension Optional {
    func oassign(to storage: inout Wrapped) {
        map {
            storage = $0
        }
    }
}
