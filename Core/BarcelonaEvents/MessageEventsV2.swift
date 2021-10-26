////  MessageEventsV2.swift
//  BarcelonaEvents
//
//  Created by Eric Rabil on 10/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension CBMessageStatusChange {
}

class MessageEventsV2: EventDispatcher {
    var cancelFunctions = [() -> ()]()
    
    override func wake() {
        cancelFunctions.append(CBDaemonListener.shared.messagePipeline.pipe { message in
            self.bus.dispatch(.itemsReceived([message.eraseToAnyChatItem()]))
        }.cancel)
        
        cancelFunctions.append(CBDaemonListener.shared.messagesDeletedPipeline.pipe { guids in
            self.bus.dispatch(.itemsRemoved(guids))
        }.cancel)
        
        cancelFunctions.append(CBDaemonListener.shared.messageStatusPipeline.pipe { status in
            self.bus.dispatch(.itemStatusChanged(status))
        }.cancel)
    }
    
    override func sleep() {
        for cancel in cancelFunctions {
            cancel()
        }
    }
}
