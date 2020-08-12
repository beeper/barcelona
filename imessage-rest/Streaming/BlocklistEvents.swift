//
//  BlocklistEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

private let CMFBlockListUpdatedNotification = Notification.Name(rawValue: "CMFBlockListUpdatedNotification")

class BlocklistEvents: EventDispatcher {
    override func wake() {
        addObserver(forName: CMFBlockListUpdatedNotification) {
            self.blockListUpdated($0)
        }
    }
    
    private func blockListUpdated(_ notification: Notification) {
        StreamingAPI.shared.dispatch(eventFor(blockListUpdated: LoadBlockList()), to: nil)
    }
}
