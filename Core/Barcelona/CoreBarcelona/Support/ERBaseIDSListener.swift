////  ERBaseIDSListener.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IDS
import Logging

fileprivate let log = Logger(label: "imagent")

extension DispatchQueue {
    static let IDSProcessingQueue = DispatchQueue(label: "com.barcelona.imagent.IDSProcessingQueue")
}

class BLDaemon {
    static let shared = BLDaemon()
    
    var services: [String: IDSService] = [:]
    
    func initialize() {
        for name in [IDSServiceNameiMessage, IDSServiceNameSMSRelay] {
            let service = IDSService(service: name)!
            
            service.addDelegate(BLServiceListener.shared, queue: .IDSProcessingQueue)
            
            services[name] = service
        }
    }
}

extension IDSDaemonController {
    static var `default`: IDSDaemonController {
        sharedInstance() as! IDSDaemonController
    }
}

enum IDSCommandID: NSInteger, CaseIterable, Codable {
    case initiate = 1
    case accept = 2
    case reject = 3
    case cancel = 4
    case relayInitiate = 5
    case relayUpdate = 6
    case relayCancel = 7
    case sendMessage = 8
    case reregister = 32
    case devicesUpdated = 34
    case emailConfirmed = 64
    case handlesUpdated = 66
    case reloadBagPush = 90
    case webTunnelRequest = 96
    case webTunnelResponse = 97
    case textMessage = 100
    case deliveryReceipt = 101
    case readReceipt = 102
    case attachmentMessage = 104
    case playedReceipt = 105
    case savedReceipt = 106
    case reflectedDeliveryReceipt = 107
    case updateAttachments = 108
    case registrationUpdateMessage = 130
    case otrNegotiation = 110
    case errorMessage = 120
    case smsTextMessage = 140
    case smsTextDownloadMessage = 141
    case smsApprovalDisplayPin = 142
    case smsOutgoing = 143
    case smsDownloadOutgoing = 144
    case smsApprovalResponse = 145
    case smsDeliveryReceipt = 146
    case smsReadReceipt = 147
    case smsEnrollMe = 148
    case smsFailure = 149
    case mcsUploadAuthToken = 150
    case mcsDownloadAuthToken = 151
    case mcsFileRefreshToken = 152
    case groupShare = 153
    case uploadFailureMessage = 155
    case offlineMessagePending = 160
    case storageEmpty = 165
    case chatSessionClose = 170
    case genericCommandMessage = 180
    case deleteSyncMessage = 181
    case genericGroupMessageCommand = 190
    case locationShareOfferCommand = 195
    case balloonTransportCommand = 196
    case niceMessage = 227
    case niceProxyOutgoingMessage = 228
    case niceProxyIncomingMessage = 229
    case niceQuickRelayAllocate = 200
    case niceGroupSessionInternalMessage = 206
    case niceGroupSessionJoin = 207
    case niceGroupSessionLeave = 208
    case niceGroupSessionUpdate = 209
    case niceGroupSessionPrekey = 210
    case niceGroupSessionMKM = 211
    case niceSessionInvitation = 232
    case niceSessionAccept = 233
    case niceSessionDecline = 234
    case niceSessionCancel = 235
    case niceSessionMessage = 236
    case niceSessionEnd = 237
    case niceSessionReinitiate = 238
    case niceGroupSessionMessage = 239
    case niceData = 242
    case niceProtobuf = 243
    case niceAppAck = 244
    case niceResource = 245
    case niceHomeKitAccessoryMessage = 250
    case niceHomeKitAccessoryReportMessage = 251
    case commandResponse = 255
}

public class ERBaseIDSListener: NSObject, IDSDaemonListenerProtocol {
    @MainActor
    public func daemonConnected() {
        BLDaemon.shared.initialize()
    }
    
    public func messageReceived(_ arg1: [AnyHashable : Any]!, withGUID arg2: String!, withPayload arg3: [AnyHashable : Any]!, forTopic arg4: String!, toIdentifier arg5: String!, fromID arg6: String!, context arg7: [AnyHashable : Any]!) {
        
    }
    
    public func protobufReceived(_ arg1: [AnyHashable : Any]!, withGUID arg2: String!, forTopic arg3: String!, toIdentifier arg4: String!, fromID arg5: String!, context arg6: [AnyHashable : Any]!) {
        
    }
    
    public func dataReceived(_ arg1: Data!, withGUID arg2: String!, forTopic arg3: String!, toIdentifier arg4: String!, fromID arg5: String!, context arg6: [AnyHashable : Any]!) {
        
    }
    
    public func receivedGroupSessionParticipantUpdate(_ arg1: [AnyHashable : Any]!, forTopic arg2: String!, toIdentifier arg3: String!, fromID arg4: String!) {
        
    }
    
    public func receivedGroupSessionParticipantDataUpdate(_ arg1: [AnyHashable : Any]!, forTopic arg2: String!, toIdentifier arg3: String!, fromID arg4: String!) {
        
    }
    
    public func sessionEndReceived(_ arg1: String!, fromID arg2: String!, with arg3: Data!) {
        
    }
    
    public func sessionCancelReceived(_ arg1: String!, fromID arg2: String!, with arg3: Data!) {
        
    }
    
    public func sessionAcceptReceived(_ arg1: String!, fromID arg2: String!, with arg3: Data!) {
        
    }
    
    public func sessionMessageReceived(_ arg1: String!, fromID arg2: String!, with arg3: Data!) {
        
    }
    
    public func session(_ arg1: String!, didReceiveReport arg2: [Any]!) {
        
    }
    
    public func sessionDeclineReceived(_ arg1: String!, fromID arg2: String!, with arg3: Data!) {
        
    }
    
    public func opportunisticDataReceived(_ arg1: Data!, withIdentifier arg2: String!, fromID arg3: String!, context arg4: [AnyHashable : Any]!) {
        
    }
    
    public func groupShareReceived(_ arg1: Data!, withGUID arg2: String!, forTopic arg3: String!, toIdentifier arg4: String!, fromID arg5: String!, context arg6: [AnyHashable : Any]!) {
        
    }
    
    public func accessoryDataReceived(_ arg1: Data!, withGUID arg2: String!, forTopic arg3: String!, toIdentifier arg4: String!, fromID arg5: String!, context arg6: [AnyHashable : Any]!) {
        
    }
    
    public func engramDataReceived(_ arg1: [AnyHashable : Any]!, withGUID arg2: String!, forTopic arg3: String!, toIdentifier arg4: String!, fromID arg5: String!, context arg6: [AnyHashable : Any]!) {
        
    }
    
    public func session(_ arg1: String!, didReceiveActiveParticipants arg2: [Any]!, success arg3: Bool) {
        
    }
    
    public func sessionInvitationReceived(withPayload arg1: [AnyHashable : Any]!, forTopic arg2: String!, sessionID arg3: String!, toIdentifier arg4: String!, fromID arg5: String!, transportType arg6: NSNumber!) {
        
    }
}
