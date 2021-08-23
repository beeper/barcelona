//
//  SubjectStream.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Combine

public func onMain<T>(_ cb: @autoclosure () -> T) -> T {
    if Thread.isMainThread { return cb() }
    else { return DispatchQueue.main.sync(execute: cb) }
}

/**
 Wraps a property to make it synchronously accessed over the main thread
 */
@propertyWrapper
public struct synchronous<Wrapped> {
    public var _wrappedValue: Wrapped
    
    @_transparent
    public var wrappedValue: Wrapped {
        get {
            onMain(_wrappedValue)
        }
        set {
            onMain(_wrappedValue = newValue)
        }
    }
    
    public init(wrappedValue: Wrapped) {
        _wrappedValue = wrappedValue
    }
}

// oh yack yack fing yack apple
@_silgen_name("dispatch_get_current_queue")
func dispatch_get_current_queue() -> DispatchQueue

@available(macOS 10.15, *)
public class SubjectStream<Element> {
    private let subject = PassthroughSubject<Element, Never>()
    private let publisher: Publishers.Share<PassthroughSubject<Element, Never>>
    
    @synchronous
    private var cancellables = Set<AnyCancellable>()
    
    /**
     Initializes the SubjectStream.
     
     - Parameter publish: the value of this parameter will be assigned a function which is used to send elements down the stream.
     */
    public init(publish: inout (Element) -> ()) {
        publisher = subject.share()
        publish = subject.send(_:)
    }
    
    /**
     Subscribes to the stream, returning a callback which unsubscribes when invoked.
     Discarding the return value means you cannot unsubscribe from this stream.
     
     - Parameter cb: The closure to be invoked when a new element is sent
     
     - Returns a callback which unsubscrubes when invoked
     */
    @discardableResult
    public func subscribe(_ cb: @escaping (Element) -> ()) -> () -> () {
        let cancellable = publisher
            .receive(on: dispatch_get_current_queue())
            .sink(receiveValue: cb)
        
        cancellable.store(in: &cancellables)
        
        return {
            self.cancellables.remove(cancellable)
        }
    }
}
/**
 A subclass of SubjectStream whose publish function is publicly accessible rather than passed via initializer.
 */
@available(macOS 10.15, *)
public class OpenSubjectStream<Element>: SubjectStream<Element> {
    public private(set) var publish: (Element) -> () = { _ in }
    
    public init() {
        super.init(publish: &publish)
    }
}
