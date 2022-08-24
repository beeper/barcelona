//
//  JBLEvents.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Combine
import BarcelonaFoundation
import Dispatch

@objc
public protocol JBLEventBusExports: JSExport {
    func emit(_ event: String, _ data: JSValue) -> Bool
    func on(_ event: String, _ callback: JSValue) -> Self
}

private extension JSValue {
    var json: String? {
        guard let stringRef = JSValueCreateJSONString(context.jsGlobalContextRef, jsValueRef, 0, nil), let string = JSStringCopyCFString(kCFAllocatorDefault, stringRef) else {
            return nil
        }
        
        return string as String
    }
    
    func decode<T: Decodable>() -> T? {
        guard let json = json, let data = json.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

@_silgen_name("dispatch_get_current_queue")
func dispatch_get_current_queue() -> DispatchQueue

//class JBLEventBus: NSObject, JBLEventBusExports {
//
//    fileprivate var context: JSContext
//    
//    public init(context: JSContext) {
//        self.context = context
//    }
//    
//    private let eventBus: EventBus = {
//        let bus = EventBus()
//        bus.resume()
//        return bus
//    }()
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    public func emit(_ event: String, _ data: JSValue) -> Bool {
//        guard let json = data.json else {
//            return false
//        }
//        
//        let superJson = "{\"type\":\"\(event)\",\"payload\":\(json)}"
//        
//        guard let superJsonData = superJson.data(using: .utf8), let decodedEvent = try? JSONDecoder().decode(Event.self, from: superJsonData) else {
//            return false
//        }
//        
//        eventBus.dispatch(decodedEvent)
//        
//        return true
//    }
//    
//    public func on(_ event: String, _ callback: JSValue) -> Self {
//        eventBus.publisher.receive(on: dispatch_get_current_queue()).filter {
//            $0.name.rawValue == event
//        }.tryMap {
//            try JSONEncoder().encode($0)
//        }.compactMap {
//            String(data: $0, encoding: .utf8)
//        }.compactMap { json in
//            JSValueMakeFromJSONString(self.context.jsGlobalContextRef, JSStringCreateWithCFString(json as CFString))
//        }.sink(receiveCompletion: { result in
//            switch result {
//            case .failure(let err):
//                CLFault("JBLEventBus", "Failed to create JSON from event: %@", err as NSError)
//            default:
//                return
//            }
//        }, receiveValue: { value in
//            callback.call(withArguments: [JSValue(jsValueRef: value, in: self.context)!])
//        }).store(in: &cancellables)
//        
//        return self
//    }
//}
