//
//  main.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona

ERBarcelonaManager.bootstrap()

let listener = NSXPCListener(machServiceName: ERBarcelonaManager.machServiceName)
let listenerDelegate = ListenerDelegate()
listener.delegate = listenerDelegate

listener.resume()

NSLog("Message XPC Service has been started")

RunLoop.current.run()
