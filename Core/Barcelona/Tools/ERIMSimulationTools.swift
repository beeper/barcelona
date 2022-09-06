//
//  ERIMSimulationTools.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Swog

private let SIMULATION_OUTGOING_ID = "+15555648583"
private let SIMULATION_INCOMING_IDS = ["iMessage"]
private let SIMULATION_MESSAGE_OFFSET = 0xc3500

class ERIMSimulationTools {
    private static var _sharedInstance: ERIMSimulationTools!
    
    static var sharedInstance: ERIMSimulationTools {
        if _sharedInstance == nil {
            _sharedInstance = ERIMSimulationTools()
        }
        
        return _sharedInstance
    }
    
    static func bootstrap() {
        CLInfo("ERIMSimulationTools", "initialized with chat GUID %@", SIMULATION_OUTGOING_ID)
    }
    
    private let iMessageAccount: IMSimulatedAccount
    private let iMessageService: IMServiceImpl
    private let loginHandle: IMHandle
    
    private init() {
        iMessageService = IMServiceImpl.service(withInternalName: "iMessage")!
        iMessageAccount = IMSimulatedAccount.init(service: iMessageService)
        loginHandle = iMessageAccount.imHandle(withID: SIMULATION_OUTGOING_ID, alreadyCanonical: false) as! IMHandle
        
        iMessageAccount.loginHandle = loginHandle
        
//        IMChatRegistry.shared.simulatedChats = ERIMSimulationTools.createPrepopulatedChats(account: iMessageAccount)
    }
    
    private static func createPrepopulatedChats(account: IMSimulatedAccount) -> [IMSimulatedChat] {
        let chat1 = IMSimulatedChat.init(incomingIDs: SIMULATION_INCOMING_IDS, messageIDOffset: UInt64(SIMULATION_MESSAGE_OFFSET), account: account)!
        let chat2 = IMSimulatedChat.init(incomingIDs: [SIMULATION_OUTGOING_ID], messageIDOffset: UInt64(0x927c1), account: account)!
        
        chat1.delegate = chat2
        chat2.delegate = chat1
        
        let baseItem = IMLocationShareStatusChangeItem.init()
        
        baseItem.status = 0
        baseItem.direction = 0
        baseItem.otherHandle = SIMULATION_OUTGOING_ID
        
        chat1._handleIncomingItem(baseItem)
        
        return [chat1, chat2]
    }
}
