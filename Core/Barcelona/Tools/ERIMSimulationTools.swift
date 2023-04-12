//
//  ERIMSimulationTools.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Logging

private let SIMULATION_OUTGOING_ID = "+15555648583"

class ERIMSimulationTools {
    static let log = Logger(label: "ERIMSimulationTools")

    static func bootstrap() {
        log.info("initialized with chat GUID \(SIMULATION_OUTGOING_ID)", source: "ERIMSimulationTools")
    }

    private let iMessageAccount: IMSimulatedAccount
    private let iMessageService: IMServiceImpl
    private let loginHandle: IMHandle

    private init() {
        iMessageService = IMServiceImpl.service(withInternalName: "iMessage")!
        iMessageAccount = IMSimulatedAccount.init(service: iMessageService)
        loginHandle = iMessageAccount.imHandle(withID: SIMULATION_OUTGOING_ID, alreadyCanonical: false)!

        iMessageAccount.loginHandle = loginHandle

        //        IMChatRegistry.shared.simulatedChats = ERIMSimulationTools.createPrepopulatedChats(account: iMessageAccount)
    }
}
