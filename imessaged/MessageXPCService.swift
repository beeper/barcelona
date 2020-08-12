//
//  MessageXPCService.swift
//  imessaged
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

class MessageXPCService: NSObject, MessageServiceProtocol {
    let running: Bool = false
    
    @objc func getRunning(replyBlock: @escaping BooleanReplyBlock) {
        replyBlock(running)
    }
}
