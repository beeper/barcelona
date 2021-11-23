/*bmi {"idKey":"command","payloadKey":"data"} bmi*/

extension IPCCommand: Codable {
    public enum IPCCommandName: String, Codable {
    	case send_message
    	case send_media
    	case send_tapback
    	case send_read_receipt
    	case set_typing
    	case get_chats
    	case get_chat
    	case get_chat_avatar
    	case get_contact
    	case get_messages_after
    	case get_recent_messages
    	case message
    	case read_receipt
    	case typing
    	case chat
    	case contact
    	case send_message_status
    	case error
    	case log
    	case response
    	case bridge_status
        case ping
        case pong
    }
    
    private enum CodingKeys: CodingKey, CaseIterable {
        case command
        case data
    }

    public var name: IPCCommandName {
        switch self {
    	case .send_message:
			return .send_message
    	case .send_media:
			return .send_media
    	case .send_tapback:
			return .send_tapback
    	case .send_read_receipt:
			return .send_read_receipt
    	case .set_typing:
			return .set_typing
    	case .get_chats:
			return .get_chats
    	case .get_chat:
			return .get_chat
    	case .get_chat_avatar:
			return .get_chat_avatar
    	case .get_contact:
			return .get_contact
    	case .get_messages_after:
			return .get_messages_after
    	case .get_recent_messages:
			return .get_recent_messages
    	case .message:
			return .message
    	case .read_receipt:
			return .read_receipt
    	case .typing:
			return .typing
    	case .chat:
			return .chat
    	case .contact:
			return .contact
    	case .send_message_status:
			return .send_message_status
    	case .error:
			return .error
    	case .log:
			return .log
    	case .response:
			return .response
    	case .bridge_status:
			return .bridge_status
        case .ping:
            return .ping
        case .pong:
            return .pong
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .command)

        switch self {
    	case .send_message(let data):
			try container.encode(data, forKey: .data)
    	case .send_media(let data):
			try container.encode(data, forKey: .data)
    	case .send_tapback(let data):
			try container.encode(data, forKey: .data)
    	case .send_read_receipt(let data):
			try container.encode(data, forKey: .data)
    	case .set_typing(let data):
			try container.encode(data, forKey: .data)
    	case .get_chats(let data):
			try container.encode(data, forKey: .data)
    	case .get_chat(let data):
			try container.encode(data, forKey: .data)
    	case .get_chat_avatar(let data):
			try container.encode(data, forKey: .data)
    	case .get_contact(let data):
			try container.encode(data, forKey: .data)
    	case .get_messages_after(let data):
			try container.encode(data, forKey: .data)
    	case .get_recent_messages(let data):
			try container.encode(data, forKey: .data)
    	case .message(let data):
			try container.encode(data, forKey: .data)
    	case .read_receipt(let data):
			try container.encode(data, forKey: .data)
    	case .typing(let data):
			try container.encode(data, forKey: .data)
    	case .chat(let data):
			try container.encode(data, forKey: .data)
    	case .contact(let data):
			try container.encode(data, forKey: .data)
    	case .send_message_status(let data):
			try container.encode(data, forKey: .data)
    	case .error(let data):
			try container.encode(data, forKey: .data)
    	case .log(let data):
			try container.encode(data, forKey: .data)
    	case .response(let data):
			try container.encode(data, forKey: .data)
    	case .bridge_status(let data):
			try container.encode(data, forKey: .data)
        case .ping:
            break
        case .pong:
            break
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let command = try container.decode(IPCCommandName.self, forKey: .command)

        switch command {
    	case .send_message:
			self = .send_message(try container.decode(SendMessageCommand.self, forKey: .data))
    	case .send_media:
			self = .send_media(try container.decode(SendMediaMessageCommand.self, forKey: .data))
    	case .send_tapback:
			self = .send_tapback(try container.decode(TapbackCommand.self, forKey: .data))
    	case .send_read_receipt:
			self = .send_read_receipt(try container.decode(SendReadReceiptCommand.self, forKey: .data))
    	case .set_typing:
			self = .set_typing(try container.decode(SendTypingCommand.self, forKey: .data))
    	case .get_chats:
			self = .get_chats(try container.decode(GetChatsCommand.self, forKey: .data))
    	case .get_chat:
			self = .get_chat(try container.decode(GetGroupChatInfoCommand.self, forKey: .data))
    	case .get_chat_avatar:
			self = .get_chat_avatar(try container.decode(GetGroupChatAvatarCommand.self, forKey: .data))
    	case .get_contact:
			self = .get_contact(try container.decode(GetContactCommand.self, forKey: .data))
    	case .get_messages_after:
			self = .get_messages_after(try container.decode(GetMessagesAfterCommand.self, forKey: .data))
    	case .get_recent_messages:
			self = .get_recent_messages(try container.decode(GetRecentMessagesCommand.self, forKey: .data))
    	case .message:
			self = .message(try container.decode(BLMessage.self, forKey: .data))
    	case .read_receipt:
			self = .read_receipt(try container.decode(BLReadReceipt.self, forKey: .data))
    	case .typing:
			self = .typing(try container.decode(BLTypingNotification.self, forKey: .data))
    	case .chat:
			self = .chat(try container.decode(BLChat.self, forKey: .data))
    	case .contact:
			self = .contact(try container.decode(BLContact.self, forKey: .data))
    	case .send_message_status:
			self = .send_message_status(try container.decode(BLMessageStatus.self, forKey: .data))
    	case .error:
			self = .error(try container.decode(ErrorCommand.self, forKey: .data))
        case .ping:
            self = .ping
        case .pong:
            self = .pong
    	case .log:
			fatalError("log cannot be decoded (yet)")
    	case .response:
			fatalError("response cannot be decoded (yet)")
    	case .bridge_status:
			self = .bridge_status(try container.decode(BridgeStatusCommand.self, forKey: .data))
        }
    }
}
