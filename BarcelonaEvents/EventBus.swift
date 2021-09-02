//
//  StreamingAPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaFoundation
import Combine

public class EventBus {
    public lazy private(set) var supervisor: DispatchSupervisor = DispatchSupervisor(center: NotificationCenter.default, bus: self)
    private let subject = PassthroughSubject<Event, Never>()
    public let publisher: AnyPublisher<Event, Never>
    public static let queue = DispatchQueue(label: "com.ericrabil.barcelona.events")
    public var queue: DispatchQueue { Self.queue }
    
    private let slidingEventFilter = ExpiringCollection<Int>()
    
    public init() {
        publisher = subject.share().receive(on: RunLoop.main).eraseToAnyPublisher()
        
        supervisor.register(MessageEvents.self)
        supervisor.register(ERMessageEvents.self)
        supervisor.register(ChatEvents.self)
        supervisor.register(BlocklistEvents.self)
        supervisor.register(ContactsEvents.self)
        supervisor.register(HealthEvents.self)
    }
    
    public func resume() {
        supervisor.wake()
    }
    
    public func pause() {
        supervisor.sleep()
    }
    
    public func dispatch(_ event: Event) {
        let hash = event.hashValue
        
        guard !slidingEventFilter.contains(hash) else {
            return
        }
        
        slidingEventFilter.insert(hash)
        subject.send(event)
    }
}

private var eventSubscriptions = Set<AnyCancellable>()

public extension Publisher where Output == Event, Failure == Never {
    func receiveEvent(_ cb: @escaping (Event) -> ()) {
        sink(receiveValue: cb).store(in: &eventSubscriptions)
    }
}

public extension Publisher where Failure == Never {
    func receiveForever(_ cb: @escaping (Output) -> ()) {
        sink(receiveValue: cb).store(in: &eventSubscriptions)
    }
}
