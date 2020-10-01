//
//  MessageServiceProtocol.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

//This file is included in both UI and XPC Service targets for the sake of simplicity.

public typealias BooleanReplyBlock = (Bool) -> ()
public typealias VoidReplyBlock = () -> ()
public typealias ErrorReplyBlock = (String?) -> ()
public typealias OptionalStringReplyBlock = (String?) -> ()
public typealias PatchReplyBlock = (xpc_object_t) -> ()

public let ERHTTPServerStatusDidChange = NSNotification.Name("ERHTTPServerStatusDidChange")
public let ERHTTPServerShouldStop = NSNotification.Name("ERHTTPServerShouldStop")
public let ERHTTPServerShouldStart = NSNotification.Name("ERHTTPServerShouldStart")
public let ERHTTPServerStatusQueried = NSNotification.Name("ERHTTPServerStatusQueried")

@objc public protocol MessageServiceProtocol {
    func stopServer(replyBlock: @escaping ErrorReplyBlock)
    func startServer(replyBlock: @escaping ErrorReplyBlock)
    func isRunning(replyBlock: @escaping BooleanReplyBlock)
    func terminate(replyBlock: @escaping VoidReplyBlock)
}

let MachServiceName = "com.ericrabil.imessage-rest"
