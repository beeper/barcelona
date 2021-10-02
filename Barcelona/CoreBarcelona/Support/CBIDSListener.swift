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

public class CBIDSListener: ERBaseIDSListener {
    public static let shared: CBIDSListener = {
        let listener = CBIDSListener()
        
//        IDSDaemonController.default.listener.addHandler(listener)

//        IDSDaemonController.default.addListenerID("com.barcelona.imagent", services: Set(arrayLiteral: IDSServiceNameiMessage), commands: Set(IDSCommandID.allCases.map(\.rawValue)))

//        IDSDaemonController.default.setCapabilities(([
//            .consumesIncomingMessages, .consumesOutgoingMessageUpdates,
//            .consumesSessionMessages, .consumesIncomingData,
//            .consumesIncomingProtobuf, .consumesIncomingResource,
//            .consumesEngram, .consumesCheckTransportLogHint,
//            .consumesAccessoryReportMessages, .consumesGroupSessionParticipantUpdates
//        ] as IDSListenerCapabilities).rawValue, forListenerID: "com.barcelona.imagent", shouldLog: true)

//        IDSDaemonController.default.connectToDaemon()

//        IDSDaemonController.default.setCommands(Set(IDSCommandID.allCases), forListenerID: IDSDaemonController.default.listenerID)
        
        return listener
    }()
    
    public let reflectedReadReceiptPipeline = CBPipeline<(messageGUID: String, chatGUID: String)>()
    
    private var myDestinationURIs: [String] {
        IMAccountController.shared.iMessageAccount?.aliases.map { IDSDestination(uri: $0).uri().prefixedURI() } ?? []
    }
    
    private var groupIDTimers: [String: Timer] = [:]
    private var groupIDCache: [String: String] = [:]
    
    private func extractGroupID(messageID: String) -> String? {
        guard let groupID = groupIDCache.removeValue(forKey: messageID) else {
            return nil
        }
        
        groupIDTimers.removeValue(forKey: groupID)?.invalidate()
        
        return groupID
    }
    
    private func cacheGIDAssociation(messageID: String, groupID: String) {
        guard groupIDCache.updateValue(groupID, forKey: messageID) == nil else {
            return
        }
        
        let timer = Timer(timeInterval: 15, repeats: false) { _ in
            self.groupIDCache[messageID] = nil
        }
        
        RunLoop.main.add(timer, forMode: .common)
        groupIDTimers[groupID] = timer
    }
    
    public override func messageReceived(_ arg1: [AnyHashable : Any]!, withGUID arg2: String!, withPayload arg3: [AnyHashable : Any]!, forTopic arg4: String!, toIdentifier arg5: String!, fromID arg6: String!, context arg7: [AnyHashable : Any]!) {
        let payload = arg1["IDSIncomingMessagePushPayload"] as! [String: Any]
        guard let rawCommand = payload["c"] as? IDSCommandID.RawValue, let command = IDSCommandID(rawValue: rawCommand) else {
            return
        }
        
        guard let guid = arg7["IDSMessageContextOriginalGUIDKey"] as? String else {
            return
        }
        
        switch command {
        case .readReceipt:
            guard let sender = payload["sP"] as? String, myDestinationURIs.contains(items: [sender, arg5]), let chatGUID = extractGroupID(messageID: guid) else {
                return
            }
            
            reflectedReadReceiptPipeline.send((guid, chatGUID))
        case .textMessage:
            guard let gid = arg3?["gid"] as? String else {
                return
            }
            
            cacheGIDAssociation(messageID: guid, groupID: gid)
        default:
            break
        }
    }
}
