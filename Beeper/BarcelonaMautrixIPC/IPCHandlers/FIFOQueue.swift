//
//  FIFOQueue.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 10/26/21.
//

import Foundation
import Pwomise

private var dispatchQueue: DispatchQueue = DispatchQueue(label: "com.barcelona.fifo")

internal class FifoQueue<Output> {
    private var queue: [() -> Promise<Void>] = [] {
        didSet {
            if oldValue.count == 0, queue.count == 1 {
                roll()
            }
        }
    }
    
    public init() {}
    
    private func roll() {
        guard queue.count > 0 else {
            return
        }
        
        let promise = queue[0]()
        
        promise.always { _ in
            self.queue.removeFirst()
            self.roll()
        }
    }
    
    public func submit(promise: @escaping () -> Promise<Output>) -> Promise<Output> {
        Promise { resolve, reject in
            dispatchQueue.async {
                self.queue.append {
                    promise().then(resolve).catch(reject)
                }
            }
        }
    }
}
