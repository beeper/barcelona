////  CBIDSListener.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IDS
import IMCore
import IMDPersistence
import IMFoundation

extension IDSListenerCapabilities {
    static func rawValue(for capabilities: IDSListenerCapabilities...) -> RawValue {
        self.init(capabilities).rawValue
    }
}

// Currently only used for monitoring read receipt reflection as fast as possible
public class CBIDSListener: ERBaseIDSListener {
    public static let shared: CBIDSListener = {
        let listener = CBIDSListener()

        IDSDaemonController.default.listener.addHandler(listener)

        IDSDaemonController.default.addListenerID(
            "com.barcelona.imagent",
            services: Set(arrayLiteral: IDSServiceNameiMessage, IDSServiceNameSMSRelay),
            commands: Set(
                [IDSCommandID.readReceipt, IDSCommandID.smsReadReceipt, .textMessage, .smsTextMessage].map(\.rawValue)
            )
        )

        IDSDaemonController.default.setCapabilities(
            IDSListenerCapabilities.rawValue(for: .consumesIncomingMessages),
            forListenerID: "com.barcelona.imagent",
            shouldLog: true
        )

        IDSDaemonController.default.connectToDaemon()

        IDSDaemonController.default.setCommands(
            Set(IDSCommandID.allCases),
            forListenerID: IDSDaemonController.default.listenerID
        )

        return listener
    }()

    public let reflectedReadReceiptPipeline = CBPipeline<(guid: String, service: IMServiceStyle, time: Date)>()

    private var myDestinationURIs: [String] {
        IMAccountController.shared.iMessageAccount?.aliases.map { IDSDestination(uri: $0).uri().prefixedURI } ?? []
    }

    private let queue = DispatchQueue(label: "com.ericrabil.ids", attributes: [], autoreleaseFrequency: .workItem)

    public override func messageReceived(
        _ arg1: [AnyHashable: Any]?,
        withGUID arg2: String?,
        withPayload arg3: [AnyHashable: Any]?,
        forTopic topic: String?,
        toIdentifier: String?,
        fromID arg6: String?,
        context arg7: [AnyHashable: Any]?
    ) {
        guard let payload = arg1?["IDSIncomingMessagePushPayload"] as? [String: Any] else {
            return
        }

        guard let rawCommand = payload["c"] as? IDSCommandID.RawValue, let command = IDSCommandID(rawValue: rawCommand)
        else {
            return
        }

        guard let rawContext = arg7, let idsContext = IDSMessageContext(dictionary: rawContext, boostContext: nil)
        else {
            return
        }

        guard let guid = idsContext.originalGUID else {
            return
        }

        let serviceName: IMServiceStyle = {
            switch topic {
            case "com.apple.madrid", "com.apple.iMessage":
                return .iMessage
            case "com.apple.private.alloy.sms", "com.apple.SMS":
                return .SMS
            default:
                return .iMessage
            }
        }()

        var uris: [String] = []
        if let sender = payload["sP"] as? String {
            uris.append(sender)
        }
        if let toIdentifier = toIdentifier, !toIdentifier.isEmpty {
            uris.append(toIdentifier)
        }

        queue.schedule {
            switch command {
            case .readReceipt, .smsReadReceipt:
                guard let timestamp = payload["e"] as? Int64, self.myDestinationURIs.contains(items: uris) else {
                    return
                }

                self.reflectedReadReceiptPipeline.send(
                    (guid, serviceName, Date(timeIntervalSince1970: Double(timestamp) / 1_000_000_000))
                )
            default:
                break
            }
        }
    }
}
