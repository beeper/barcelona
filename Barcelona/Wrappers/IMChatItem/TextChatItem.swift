//
//  TextChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import AnyCodable
import IMCore

private let regex = try! NSRegularExpression(pattern: "<body.*?>([\\s\\S]*)<\\/body>")

enum TextContentType: String, Codable {
    case link
    case calendar
    case breadcrumb
    case text
}

public struct TextPart: Codable, Hashable {
    var type: TextContentType
    var string: String
    var data: AnyCodable?
    var attributes: [TextPartAttribute]?
}

public enum TextPartAttribute: Codable, Hashable {
    case bold(Int)
    case italic(Int)
    case underline(Int)
    case strike(Int)
    case writingDirection(Int)
    case link(String)
    case breadcrumbMarker(String)
    case breadcrumbOptions(Int)
    case mention(String)
    
    private enum CodingKeys: String, Codable, CodingKey {
        case key, value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var attribute: TextPartAttribute? = nil
        
        let key = try container.decode(String.self, forKey: .key)
        
        switch key {
        case "bold":
            fallthrough
        case "italic":
            fallthrough
        case "underline":
            fallthrough
        case "strike":
            fallthrough
        case "breadcrumbOptions":
            fallthrough
        case "writingDirection":
            attribute = TextPartAttribute(rawKey: key, rawValue: try container.decode(Int.self, forKey: .value))
        case "mention":
            fallthrough
        case "breadcrumbMarker":
            fallthrough
        case "link":
            attribute = TextPartAttribute(rawKey: key, rawValue: try container.decode(String.self, forKey: .value))
        default:
            throw BarcelonaError(code: 400, message: "Invalid attribute key")
        }
        
        guard attribute != nil else {
            throw BarcelonaError(code: 400, message: "Invalid attribute key")
        }
        
        self = attribute!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .key)
        try container.encode(value, forKey: .value)
    }
    
    public init?(rawKey key: String, rawValue value: Int) {
        switch key {
        case "bold":
            self = .bold(value)
        case "italic":
            self = .italic(value)
        case "underline":
            self = .underline(value)
        case "strike":
            self = .strike(value)
        case "writingDirection":
            self = .writingDirection(value)
        case "breadcrumbOptions":
            self = .breadcrumbOptions(value)
        default:
            return nil
        }
    }
    
    public init?(rawKey key: String, rawValue value: String) {
        switch key {
        case "link":
            self = .link(value)
        case "breadcrumbMarker":
            self = .breadcrumbMarker(value)
        case "mention":
            self = .mention(value)
        default:
            return nil
        }
    }
    
    public init?(attributedKey key: NSAttributedString.Key, rawValue value: Any) {
        guard let enumKey = TextPartAttribute.enumKey(forAttributedKey: key) else {
            return nil
        }
        
        switch enumKey {
        case "bold":
            fallthrough
        case "italic":
            fallthrough
        case "strike":
            fallthrough
        case "underline":
            fallthrough
        case "breadcrumbOptions":
            fallthrough
        case "writingDirection":
            guard let intValue = value as? Int ?? Int(value as? String ?? "illegal"), let attribute = TextPartAttribute(rawKey: enumKey, rawValue: intValue) else {
                return nil
            }
            self = attribute
        case "mention":
            fallthrough
        case "breadcrumbMarker":
            guard let stringValue = value as? String, let attribute = TextPartAttribute(rawKey: enumKey, rawValue: stringValue) else {
                return nil
            }
            self = attribute
        case "link":
            guard let urlValue = value as? URL, let attribute = TextPartAttribute(rawKey: enumKey, rawValue: urlValue.absoluteString) else {
                return nil
            }
            self = attribute
        default:
            return nil
        }
    }
    
    public var stringValue: String? {
        return self.value.value as? String
    }
    
    public var intValue: Int? {
        return self.value.value as? Int
    }
    
    public var boolValue: Bool? {
        return self.value.value as? Bool
    }
    
    public var value: AnyCodable {
        switch self {
        case .bold(let value):
            return .init(value)
        case .italic(let value):
            return .init(value)
        case .strike(let value):
            return .init(value)
        case .underline(let value):
            return .init(value)
        case .link(let value):
            return .init(value)
        case .writingDirection(let value):
            return .init(value)
        case .breadcrumbMarker(let value):
            return .init(value)
        case .breadcrumbOptions(let value):
            return .init(value)
        case .mention(let value):
            return .init(value)
        }
    }
    
    public static func enumKey(forAttributedKey key: NSAttributedString.Key) -> String? {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            switch key {
            case MessageAttributes.mentionName:
                return "mention"
            default:
                break
            }
        }
        
        switch key {
        case MessageAttributes.bold:
            return "bold"
        case MessageAttributes.italic:
            return "italic"
        case MessageAttributes.strike:
            return "strike"
        case MessageAttributes.underline:
            return "underline"
        case MessageAttributes.link:
            return "link"
        case MessageAttributes.writingDirection:
            return "writingDirection"
        case MessageAttributes.breadcrumbMarker:
            return "breadcrumbMarker"
        case MessageAttributes.breadcrumbOptions:
            return "breadcrumbOptions"
        default:
            return nil
        }
    }
    
    public var name: String {
        switch self {
        case .bold:
            return "bold"
        case .italic:
            return "italic"
        case .underline:
            return "underline"
        case .strike:
            return "strike"
        case .link:
            return "link"
        case .writingDirection:
            return "writingDirection"
        case .breadcrumbMarker:
            return "breadcrumbMarker"
        case .breadcrumbOptions:
            return "breadcrumbOptions"
        case .mention:
            return "mention"
        }
    }
    
    public var attributedKey: NSAttributedString.Key {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            switch self {
            case .mention:
                return MessageAttributes.mentionName
            default:
                break
            }
        }
        
        switch self {
        case .bold:
            return MessageAttributes.bold
        case .italic:
            return MessageAttributes.italic
        case .underline:
            return MessageAttributes.underline
        case .strike:
            return MessageAttributes.strike
        case .link:
            return MessageAttributes.link
        case .writingDirection:
            return MessageAttributes.writingDirection
        case .breadcrumbOptions:
            return MessageAttributes.breadcrumbOptions
        case .breadcrumbMarker:
            return MessageAttributes.breadcrumbMarker
        case .mention:
            return MessageAttributes.bold
        }
    }
    
    public var attributedValue: Any {
        switch self {
        case .link:
            if let stringValue = stringValue, let url = URL(string: stringValue) {
                return url
            }
            return value.value
        default:
            return value.value
        }
    }
}

public struct TextChatItem: ChatItem, ChatItemAcknowledgable, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMTextMessagePartChatItem.self]
    
    public init?(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMTextMessagePartChatItem, parts: context.textParts, chatID: context.chatID)
    }
    
    init(_ item: IMTextMessagePartChatItem, parts: [TextPart]? = nil, chatID: String?) {
        self.text = item.text?.string ?? ""
        self.parts = parts ?? ERTextParts(from: item.text ?? NSAttributedString())
        self.subject = item.subject?.string
        
        self.load(item: item, chatID: chatID)
    }
    
    init(_ item: IMTranscriptPluginChatItem, text: String, parts: [TextPart], chatID: String?) {
        self.parts = parts
        self.text = text
        
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var parts: [TextPart]
    public var text: String
    public var subject: String?
    public var acknowledgments: [AcknowledgmentChatItem]?
    
    public var type: ChatItemType {
        .text
    }
    
    public var debugDescription: String {
        "\(type) { id=\(id.debugString) fromMe=\(fromMe.debugString) text=\(text) }"
    }
}
