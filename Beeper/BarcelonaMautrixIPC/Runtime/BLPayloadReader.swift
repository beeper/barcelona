//
//  BLPayloadReader.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
// import BarcelonaFoundation
import BarcelonaMautrixIPCProtobuf

public class BLPayloadReader {
    public var callback: (PBPayload) -> () = { _ in }
    
    public var ready = ProcessInfo.processInfo.arguments.contains("-d") {
        didSet {
            if ready {
                let queue = queue
                self.queue = []
                
                queue.forEach(callback)
            }
        }
    }
    
    private var queue = [PBPayload]()
    
    public init() {
        BLCreatePayloadReader { payload in
            if self.ready {
                self.callback(payload)
            } else {
                self.queue.append(payload)
            }
        }
    }
}
