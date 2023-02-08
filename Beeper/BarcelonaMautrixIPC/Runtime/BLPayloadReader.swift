//
//  BLPayloadReader.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Combine
import Foundation
import BarcelonaFoundation

public class BLPayloadReader {
    private let ipcChannel: MautrixIPCChannel
    
    private var queue = [IPCPayload]()
    
    private var bag = Set<AnyCancellable>()
    
    public init(ipcChannel: MautrixIPCChannel) {
        self.ipcChannel = ipcChannel
        
        ipcChannel.receivedPayloads
            .sink { [weak self] in
                guard let self else { return }
                
                if self.ready {
                    BLHandlePayload($0, ipcChannel: ipcChannel)
                } else {
                    self.queue.append($0)
                }
            }
            .store(in: &bag)
        
        if ProcessInfo.processInfo.arguments.contains("-d") {
            self.ready = true
        }
    }
    
    public var ready = false {
        didSet {
            let queue = queue
            
            queue.forEach { BLHandlePayload($0, ipcChannel: self.ipcChannel) }
        }
    }
}
