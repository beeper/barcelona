//
//  MessageXPCService.swift
//  imessage-rest
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaVapor
import BarcelonaFoundation

class MessageXPCService: NSObject, MessageServiceProtocol {
    @objc func stopServer(replyBlock: @escaping ErrorReplyBlock) {
        ERBarcelonaAPIService.sharedInstance.stop { error in
            replyBlock(error?.localizedDescription)
        }
    }
    
    @objc func startServer(replyBlock: @escaping ErrorReplyBlock) {
        ERBarcelonaAPIService.sharedInstance.start { error in
            replyBlock(error?.localizedDescription)
        }
    }
    
    @objc func isRunning(replyBlock: @escaping BooleanReplyBlock) {
        replyBlock(ERHTTPServer.shared.running)
    }
    
    @objc func terminate(replyBlock: @escaping VoidReplyBlock) {
        replyBlock()
        exit(0)
    }
}
