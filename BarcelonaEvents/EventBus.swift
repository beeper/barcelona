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
    public let messageStream: AnyPublisher<Message, Never>
    public let receivedMessageStream: AnyPublisher<Message, Never>
    public let itemStatusStream: AnyPublisher<StatusChatItem, Never>
    public let queue = DispatchQueue(label: "com.ericrabil.barcelona.events")

    private let slidingEventFilter = ExpiringCollection<Int>()
    
    public init() {
        publisher = subject.share().receive(on: RunLoop.main).eraseToAnyPublisher()
        
        messageStream = publisher.compactMap { event -> [ChatItem]? in
            switch event {
            case .itemsReceived(let items):
                return items
            default:
                return nil
            }
        }.flatMap {
            $0.compactMap {
                $0 as? Message
            }.publisher
        }.share().eraseToAnyPublisher()
        
        receivedMessageStream = messageStream.filter {
            !($0.fromMe ?? false)
        }.share().eraseToAnyPublisher()
        
        itemStatusStream = publisher.compactMap {
            switch $0 {
            case .itemStatusChanged(let item):
                return item
            default:
                return nil
            }
        }.share().eraseToAnyPublisher()
        
        supervisor.register(MessageEvents.self)
        supervisor.register(ERMessageEvents.self)
        supervisor.register(ChatEvents.self)
        supervisor.register(BlocklistEvents.self)
        supervisor.register(ContactsEvents.self)
        
        #if DEBUG_DEDUPLICATE_EVENTS
        // deduplicate (this will leak memory, so, cry)
        
        var payloads = Set<String>()
        
        publisher.receiveEvent { event in
            let json = try! JSONEncoder().encode(event).base64EncodedString()
            
            if payloads.contains(json) {
                fatalError("duplicate payload detected!!!")
            }
            
            payloads.insert(json)
        }
        #endif
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

