////  CBIDSListener.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IDS
import IMFoundation
import IMDPersistence

// Currently only used for monitoring read receipt reflection as fast as possible
public class CBIDSListener: ERBaseIDSListener {
    public static let shared: CBIDSListener = {
        let listener = CBIDSListener()
        
        IDSDaemonController.default.listener.addHandler(listener)

        IDSDaemonController.default.addListenerID("com.barcelona.imagent", services: Set(arrayLiteral: IDSServiceNameiMessage), commands: Set(IDSCommandID.allCases.map(\.rawValue)))

        IDSDaemonController.default.setCapabilities(IDSListenerCapabilities.consumesIncomingMessages.rawValue, forListenerID: "com.barcelona.imagent", shouldLog: true)

        IDSDaemonController.default.connectToDaemon()

        IDSDaemonController.default.setCommands(Set(IDSCommandID.allCases), forListenerID: IDSDaemonController.default.listenerID)
        
        return listener
    }()
    
    public let reflectedReadReceiptPipeline = CBPipeline<(guid: String, time: Date)>()
    
    private var myDestinationURIs: [String] {
        IMAccountController.shared.iMessageAccount?.aliases.map { IDSDestination(uri: $0).uri().prefixedURI() } ?? []
    }
    
    public override func messageReceived(_ arg1: [AnyHashable : Any]!, withGUID arg2: String!, withPayload arg3: [AnyHashable : Any]!, forTopic arg4: String!, toIdentifier arg5: String!, fromID arg6: String!, context arg7: [AnyHashable : Any]!) {
        let payload = arg1["IDSIncomingMessagePushPayload"] as! [String: Any]
        guard let rawCommand = payload["c"] as? IDSCommandID.RawValue, let command = IDSCommandID(rawValue: rawCommand) else {
            return
        }
        
        guard let idsContext = IDSMessageContext(dictionary: arg7, boostContext: nil) else {
            return
        }
        
        guard let guid = idsContext.originalGUID else {
            return
        }
        
        switch command {
        case .readReceipt:
            guard let sender = payload["sP"] as? String, let timestamp = payload["e"] as? Int64, myDestinationURIs.contains(items: [sender, arg5]) else {
                return
            }
            
            reflectedReadReceiptPipeline.send((guid, Date(timeIntervalSince1970: Double(timestamp) / 1000000000)))
        default:
            break
        }
    }
}
