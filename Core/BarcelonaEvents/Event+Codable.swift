/*bmi {"idKey":"type","payloadKey":"payload"} bmi*/
import Barcelona

extension Event: Codable {
    public enum EventName: String, Codable {
    	case bootstrap
    	case itemsReceived
    	case itemsUpdated
    	case itemStatusChanged
    	case itemsRemoved
    	case participantsChanged
    	case conversationRemoved
    	case conversationCreated
    	case conversationChanged
    	case conversationDisplayNameChanged
    	case conversationJoinStateChanged
    	case conversationUnreadCountChanged
    	case conversationPropertiesChanged
    	case contactCreated
    	case contactRemoved
    	case contactUpdated
    	case blockListUpdated
    }
    
    private enum CodingKeys: CodingKey, CaseIterable {
        case type
        case payload
    }

    public var name: EventName {
        switch self {
    	case .bootstrap:
			return .bootstrap
    	case .itemsReceived:
			return .itemsReceived
    	case .itemsUpdated:
			return .itemsUpdated
    	case .itemStatusChanged:
			return .itemStatusChanged
    	case .itemsRemoved:
			return .itemsRemoved
    	case .participantsChanged:
			return .participantsChanged
    	case .conversationRemoved:
			return .conversationRemoved
    	case .conversationCreated:
			return .conversationCreated
    	case .conversationChanged:
			return .conversationChanged
    	case .conversationDisplayNameChanged:
			return .conversationDisplayNameChanged
    	case .conversationJoinStateChanged:
			return .conversationJoinStateChanged
    	case .conversationUnreadCountChanged:
			return .conversationUnreadCountChanged
    	case .conversationPropertiesChanged:
			return .conversationPropertiesChanged
    	case .contactCreated:
			return .contactCreated
    	case .contactRemoved:
			return .contactRemoved
    	case .contactUpdated:
			return .contactUpdated
    	case .blockListUpdated:
			return .blockListUpdated
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .type)

        switch self {
    	case .bootstrap(let payload):
			try container.encode(payload, forKey: .payload)
    	case .itemsReceived(let payload):
			try container.encode(payload, forKey: .payload)
    	case .itemsUpdated(let payload):
			try container.encode(payload, forKey: .payload)
    	case .itemStatusChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .itemsRemoved(let payload):
			try container.encode(payload, forKey: .payload)
    	case .participantsChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationRemoved(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationCreated(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationDisplayNameChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationJoinStateChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationUnreadCountChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .conversationPropertiesChanged(let payload):
			try container.encode(payload, forKey: .payload)
    	case .contactCreated(let payload):
			try container.encode(payload, forKey: .payload)
    	case .contactRemoved(let payload):
			try container.encode(payload, forKey: .payload)
    	case .contactUpdated(let payload):
			try container.encode(payload, forKey: .payload)
    	case .blockListUpdated(let payload):
			try container.encode(payload, forKey: .payload)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(EventName.self, forKey: .type)
        
        switch type {
    	case .bootstrap:
			self = .bootstrap(try container.decode(BootstrapData.self, forKey: .payload))
    	case .itemsReceived:
			self = .itemsReceived(try container.decode([AnyChatItem].self, forKey: .payload))
    	case .itemsUpdated:
			self = .itemsUpdated(try container.decode([AnyChatItem].self, forKey: .payload))
    	case .itemStatusChanged:
			self = .itemStatusChanged(try container.decode(CBMessageStatusChange.self, forKey: .payload))
    	case .itemsRemoved:
			self = .itemsRemoved(try container.decode([String].self, forKey: .payload))
    	case .participantsChanged:
			self = .participantsChanged(try container.decode(ParticipantChangeRecord.self, forKey: .payload))
    	case .conversationRemoved:
			self = .conversationRemoved(try container.decode(String.self, forKey: .payload))
    	case .conversationCreated:
			self = .conversationCreated(try container.decode(Chat.self, forKey: .payload))
    	case .conversationChanged:
			self = .conversationChanged(try container.decode(Chat.self, forKey: .payload))
    	case .conversationDisplayNameChanged:
			self = .conversationDisplayNameChanged(try container.decode(Chat.self, forKey: .payload))
    	case .conversationJoinStateChanged:
			self = .conversationJoinStateChanged(try container.decode(Chat.self, forKey: .payload))
    	case .conversationUnreadCountChanged:
			self = .conversationUnreadCountChanged(try container.decode(Chat.self, forKey: .payload))
    	case .conversationPropertiesChanged:
			self = .conversationPropertiesChanged(try container.decode(ChatConfigurationRepresentation.self, forKey: .payload))
    	case .contactCreated:
			self = .contactCreated(try container.decode(Contact.self, forKey: .payload))
    	case .contactRemoved:
			self = .contactRemoved(try container.decode(String.self, forKey: .payload))
    	case .contactUpdated:
			self = .contactUpdated(try container.decode(Contact.self, forKey: .payload))
    	case .blockListUpdated:
			self = .blockListUpdated(try container.decode(BulkHandleIDRepresentation.self, forKey: .payload))
        }
    }
}
