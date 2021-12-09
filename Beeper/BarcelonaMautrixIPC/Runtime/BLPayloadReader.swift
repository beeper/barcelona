//
//  BLPayloadReader.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

public class BLPayloadReader {
    public let stream: SubjectStream<IPCPayload>
    private let publish: (IPCPayload) -> ()
    
    public var ready = ProcessInfo.processInfo.arguments.contains("-d") {
        didSet {
            if ready {
                let queue = queue
                self.queue = []
                
                queue.forEach(publish)
            }
        }
    }
    
    private var queue = [IPCPayload]()
    
    public init() {
        var publish: (IPCPayload) -> () = { _ in }
        
        self.stream = SubjectStream(publish: &publish)
        self.publish = publish
        
        BLCreatePayloadReader { payload in
            if self.ready {
                self.publish(payload)
            } else {
                self.queue.append(payload)
            }
        }
    }
}
