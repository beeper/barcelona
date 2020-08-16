//
//  MessageServiceProtocol.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

//This file is included in both UI and XPC Service targets for the sake of simplicity.

typealias BooleanReplyBlock = (Bool) -> ()

@objc protocol MessageServiceProtocol {
    func getRunning(replyBlock: @escaping BooleanReplyBlock)
}
