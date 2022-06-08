//
//  ChatItem-Protocols.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

#if os(iOS)
private extension NSObject {
    static var className: String {
        NSStringFromClass(self)
    }
    
    var className: String {
        NSStringFromClass(object_getClass(self)!)
    }
}
#endif

private extension ChatItem {
    static var ingestionPairs: [(String, ChatItem.Type)] {
        ingestionClasses.map {
            #if os(iOS)
            ($0.className, self)
            #else
            ($0.className(), self)
            #endif
        }
    }
}

public enum ChatItemType: String, Codable, CaseIterable {
    case date
    case sender
    case participantChange
    case attachment
    case status
    case groupAction
    case plugin
    case text
    case acknowledgment
    case message
    case phantom
    case groupTitle
    case typing
    case sticker
    case action
    case error
    
    static let ingestionMapping: [String: ChatItem.Type] = allCases.flatMap { $0.decodingClass.ingestionPairs }.dictionary(keyedBy: \.0, valuedBy: \.1)
    
    @usableFromInline
    static func ingest(object: NSObject, context: IngestionContext) -> ChatItem {
        ingestionMapping[object.className]?.init(ingesting: object, context: context) ?? PhantomChatItem(object, chatID: context.chatID)
    }
    
    static let transcriptItems: [ChatItemType] = [
        .participantChange, .groupAction, .groupTitle, .typing
    ]
    
    static let chatItems: [ChatItemType] = [
        .action, .attachment, .plugin,
        .text, .acknowledgment,
        .sticker, .message
    ]
    
    var decodingClass: ChatItem.Type {
        switch self {
        case .date:
            return DateItem.self
        case .sender:
            return SenderItem.self
        case .participantChange:
            return ParticipantChangeItem.self
        case .attachment:
            return AttachmentChatItem.self
        case .status:
            return StatusChatItem.self
        case .groupAction:
            return GroupActionItem.self
        case .plugin:
            return PluginChatItem.self
        case .text:
            return TextChatItem.self
        case .acknowledgment:
            return AcknowledgmentChatItem.self
        case .message:
            return Message.self
        case .phantom:
            return PhantomChatItem.self
        case .groupTitle:
            return GroupTitleChangeItem.self
        case .typing:
            return TypingItem.self
        case .sticker:
            return StickerChatItem.self
        case .action:
            return ActionChatItem.self
        case .error:
            return ErrorChatItem.self
        }
    }
}

public struct IngestionContext {
    
    public init(chatID: String) {
        self.chatID = chatID
    }
    
    public let chatID: String
    public let attachment: Attachment? = nil
    public let textParts: [TextPart]? = nil
    public let text: String? = nil
    public let message: IMMessage? = nil
    
    
}

internal extension Optional where Wrapped == String {
    var debugString: String {
        self ?? "(nil)"
    }
}

internal extension Optional where Wrapped == Bool {
    var debugString: String {
        (self ?? false).description
    }
}

@_typeEraser(AnyChatItem)
public protocol ChatItem: Codable, CustomDebugStringConvertible {
    static var ingestionClasses: [NSObject.Type] { get }
    
    init?(ingesting item: NSObject, context: IngestionContext)
    
    var id: String { get set }
    var chatID: String { get set }
    var fromMe: Bool { get set }
    var time: Double { get set }
    var threadIdentifier: String? { get set }
    var threadOriginator: String? { get set }
    var type: ChatItemType { get }
    var isTranscriptItem: Bool { get }
    var isChatItem: Bool { get }
    var isMessage: Bool { get }
    var isNotMessage: Bool { get }
    
    func hash(into hasher: inout Hasher)
}

public extension ChatItem {
    var debugDescription: String {
        "\(type) { id=\(id) fromMe=\(fromMe) }"
    }
}

extension ChatItem {
    public func eraseToAnyChatItem() -> AnyChatItem {
        if let item = self as? AnyChatItem {
            return item
        }
        
        return AnyChatItem(erasing: self)
    }
    
    public var isTranscriptItem: Bool {
        ChatItemType.transcriptItems.contains(type)
    }
    
    public var isChatItem: Bool {
        ChatItemType.chatItems.contains(type)
    }
    
    public var isMessage: Bool {
        type == .message
    }
    
    public var isNotMessage: Bool {
        type != .message
    }
    
    public var isAcknowledgable: Bool {
        self is ChatItemAcknowledgable
    }
}

public protocol ChatItemOwned: ChatItem {
    var sender: String? { get set }
}

public protocol ChatItemAssociable: ChatItemOwned {
    var associatedID: String { get set }
}

public protocol ChatItemAcknowledgable: ChatItem {
    var acknowledgments: [AcknowledgmentChatItem]? { get set }
}

public class AnyChatItem: ChatItem, Hashable, ChatItemOwned, ChatItemAcknowledgable {
    public static func == (lhs: AnyChatItem, rhs: AnyChatItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        item.hash(into: &hasher)
    }
    
    public static var ingestionClasses: [NSObject.Type] { [] }
    
    public var id: String { get { item.id } set { item.id = newValue } }
    public var chatID: String { get { item.chatID } set { item.chatID = newValue } }
    public var fromMe: Bool { get { item.fromMe } set { item.fromMe = newValue } }
    public var time: Double { get { item.time } set { item.time = newValue } }
    public var threadIdentifier: String? { get { item.threadIdentifier } set { item.threadIdentifier = newValue } }
    public var threadOriginator: String? { get { item.threadOriginator } set { item.threadOriginator = newValue } }
    public var type: ChatItemType { item.type }
    public var sender: String? {
        get {
            (item as? ChatItemOwned)?.sender
        }
        set {
            guard var item = item as? ChatItemOwned else {
                return
            }
            
            item.sender = newValue
            self.item = item
        }
    }
    
    public var associatedID: String? {
        get {
            (item as? ChatItemAssociable)?.associatedID
        }
        set {
            guard var item = item as? ChatItemAssociable, let id = newValue else {
                return
            }
            
            item.associatedID = id
            self.item = item
        }
    }
    
    public var acknowledgments: [AcknowledgmentChatItem]? {
        get {
            (item as? ChatItemAcknowledgable)?.acknowledgments
        }
        set {
            guard var item = item as? ChatItemAcknowledgable else {
                return
            }
            
            item.acknowledgments = newValue
            self.item = item
        }
    }
    
    public var isAcknowledgable: Bool {
        item is ChatItemAcknowledgable
    }
    
    public private(set) var item: ChatItem
    
    public init<T: ChatItem>(erasing item: T) {
        self.item = item
    }
    
    public required init(ingesting item: NSObject, context: IngestionContext) {
        self.item = ChatItemType.ingest(object: item, context: context)
    }
    
    public init(_ item: ChatItem) {
        self.item = item
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(ChatItemType.self, forKey: .type)
        item = try type.decodingClass.init(from: container.superDecoder(forKey: .payload))
    }
    
    private enum CodingKeys: CodingKey {
        case payload, type
    }
    
    private func setting<Proto: ChatItem>(type: Proto.Type, _ cb: (inout Proto) -> ()) {
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try item.encode(to: container.superEncoder(forKey: .payload))
        try container.encode(type, forKey: .type)
    }
    
    public var debugDescription: String {
        item.debugDescription
    }
}
