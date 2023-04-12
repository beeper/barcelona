////  CBIDSConnection.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//  Ported from https://github.com/open-imcore/valenciad
//

import Foundation
import IDS

class BLServiceListener: IDSServiceDelegate {
    static let shared = BLServiceListener()

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        incomingMessage message: [AnyHashable: Any]!,
        fromID: String!,
        context: IDSMessageContext!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        incomingData data: Data!,
        fromID: String!,
        context: IDSMessageContext!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        incomingResourceAt resourceURL: URL!,
        fromID: String!,
        context: IDSMessageContext!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        identifier: String!,
        didSendWithSuccess success: Bool,
        error: Error!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        identifier: String!,
        hasBeenDeliveredWithContext context: Any!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        identifier: String!,
        fromID: String!,
        hasBeenDeliveredWithContext context: Any!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        identifier: String!,
        didSendWithSuccess success: Bool,
        error: Error!,
        context: IDSMessageContext!
    ) {
    }

    func service(
        _ service: IDSService!,
        account: IDSAccount!,
        incomingResourceAt resourceURL: URL!,
        metadata: [AnyHashable: Any]!,
        fromID: String!,
        context: IDSMessageContext!
    ) {
    }
}

struct IDSListenerCapabilities: OptionSet, ExpressibleByIntegerLiteral {
    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(integerLiteral literal: UInt32) {
        self.init(rawValue: literal)
    }

    var rawValue: UInt32

    typealias RawValue = UInt32

    static let consumesIncomingMessages: IDSListenerCapabilities = 1
}
