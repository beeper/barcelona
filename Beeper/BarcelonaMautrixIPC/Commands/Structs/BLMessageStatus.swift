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
        statusCode: String? = nil,
        correlation_id: String? = nil,
        sender_correlation_id: String? = nil
    ) {
        self.guid = guid
        self.chatGUID = chatGUID
        self.status = status
        self.service = service
        self.message = message
        self.statusCode = statusCode
        self.correlationID = correlation_id
        self.senderCorrelationID = sender_correlation_id
    }

    public init(
        sentMessageGUID: String,
        onService: String,
        forChatGUID: String,
        correlation_id: String? = nil,
        sender_correlation_id: String? = nil
    ) {
        guid = sentMessageGUID
        chatGUID = forChatGUID
        status = .sent
        message = nil
        statusCode = nil
        service = onService
        correlationID = correlation_id
        senderCorrelationID = sender_correlation_id
    }

    public enum StatusEvent: String, Codable {
        case sent, failed
    }

    public var guid: String
    public var chatGUID: String
    public var status: StatusEvent
    public var service: String
    public var message: String?
    public var statusCode: String?
    public var correlationID: String?
    public var senderCorrelationID: String?

    public enum CodingKeys: String, CodingKey {
        case guid
        case chatGUID = "chat_guid"
        case status, service, message
        case statusCode = "status_code"
        case correlationID = "correlation_id"
        case senderCorrelationID = "sender_correlation_id"
    }
}
