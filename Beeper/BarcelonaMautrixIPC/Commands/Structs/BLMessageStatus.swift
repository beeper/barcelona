//
//  BLMessageStatus.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation

public struct BLMessageStatus: Codable {
    public init(
        guid: String,
        chatGUID: String,
        status: BLMessageStatus.StatusEvent,
        service: String,
        message: String? = nil,
        statusCode: String? = nil
    ) {
        self.guid = guid
        self.chatGUID = chatGUID
        self.status = status
        self.service = service
        self.message = message
        self.statusCode = statusCode
    }

    public init(
        sentMessageGUID: String,
        onService: String,
        forChatGUID: String
    ) {
        guid = sentMessageGUID
        chatGUID = forChatGUID
        status = .sent
        message = nil
        statusCode = nil
        service = onService
    }

    public enum StatusEvent: String, Codable {
        case delivered, sent, failed
    }

    public var guid: String
    public var chatGUID: String
    public var status: StatusEvent
    public var service: String
    public var message: String?
    public var statusCode: String?

    public enum CodingKeys: String, CodingKey {
        case guid
        case chatGUID = "chat_guid"
        case status, service, message
        case statusCode = "status_code"
    }
}
