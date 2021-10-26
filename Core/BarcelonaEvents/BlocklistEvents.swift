//
//  BlocklistEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

private let CMFBlockListUpdatedNotification = Notification.Name(rawValue: "CMFBlockListUpdatedNotification")
private let Log = Logger(category: "BlocklistEvents")

/**
 Tracks events related to CommunicationsFilter.framework
 */
public class BlocklistEvents: EventDispatcher {
    public override func wake() {
        addObserver(forName: CMFBlockListUpdatedNotification) {
            self.blockListUpdated($0)
        }
    }
    
    private func blockListUpdated(_ notification: Notification) {
        Log.debug("Blocklist updated!")
        bus.dispatch(.blockListUpdated(CBLoadBlocklist()))
    }
}
