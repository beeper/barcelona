//
//  Query.swift
//  grapple
//
//  Created by Eric Rabil on 11/24/21.
//

import Foundation
import SwiftCLI
import IMCore

struct EncodingBox: Encodable {
    var ref: (Encoder) throws -> ()
    
    init(encodable: Encodable) {
        ref = encodable.encode(to:)
    }
    
    func encode(to encoder: Encoder) throws {
        try ref(encoder)
    }
}

var visited: Set<NSObject> = Set()

// Look up a bunch of methods/impls on NSInvocation
let nsInvocationClass: AnyClass = NSClassFromString("NSInvocation")!

// Look up the "invocationWithMethodSignature:" method
let nsInvocationInitializer = unsafeBitCast(
    method_getImplementation(
        class_getClassMethod(nsInvocationClass, NSSelectorFromString("invocationWithMethodSignature:"))!
    ),
    to: (@convention(c) (AnyClass?, Selector, Any?) -> Any).self
)

// Look up the "setSelector:" method
let nsInvocationSetSelector = unsafeBitCast(
    class_getMethodImplementation(nsInvocationClass, NSSelectorFromString("setSelector:")),
    to:(@convention(c) (Any, Selector, Selector) -> Void).self
)

let nsInvocationSetTarget = unsafeBitCast(
    class_getMethodImplementation(nsInvocationClass, NSSelectorFromString("setTarget:")),
    to: (@convention(c) (NSObject, Selector, NSObject) -> Void).self
)

let nsInvocationRetainArguments = unsafeBitCast(
    class_getMethodImplementation(nsInvocationClass, NSSelectorFromString("retainArguments")),
    to: (@convention(c) (NSObject, Selector) -> Void).self
)

let nsInvocationInvoke = unsafeBitCast(
    class_getMethodImplementation(nsInvocationClass, NSSelectorFromString("invoke")),
    to: (@convention(c) (NSObject, Selector) -> Void).self
)

let nsInvocationGetReturnValue = unsafeBitCast(
    class_getMethodImplementation(nsInvocationClass, NSSelectorFromString("getReturnValue:")),
    to: (@convention(c) (NSObject, Selector, UnsafeMutableRawPointer) -> Void).self
)

let invokeWithTargetSelector = NSSelectorFromString("invokeWithTarget:")
var result: UnsafeMutableRawPointer = .allocate(byteCount: 0, alignment: 0)

#if os(iOS)
extension NSObject {
    var className: String {
        NSStringFromClass(Self.self)
    }
}
#endif

extension NSObject: Encodable {
    var propertyBlacklist: [String] {
        switch self {
        case is IMAccount:
            return ["accountImageData", "arrayOfAllIMHandles", "service"]
        case is IMHandle:
            return ["siblingsArray", "account", "siblings", "service"]
        case is IMService:
            return ["siblingServices"]
        case is IMChat:
            return ["autoDonateMessages", "chatRegistry"]
        default:
            return ["_isSymbolImage", "defaultSize", "_symbolImage", "bitmapData", "CGImage", "colorSyncProfile", "CGColorSpace", "_animated", "_mapkit_CLDenied", "_mapkit_CLLocationUnknown"]
        }
    }
    
    var properties: [String] {
        var count: UInt32 = 0
        guard let propertyList = class_copyPropertyList(Self.self, &count) else {
            return []
        }
        
        defer { free(propertyList) }
        
        return UnsafeMutableBufferPointer(start: propertyList, count: Int(count)).map(property_getName(_:)).map(String.init(cString:)).filter { !propertyBlacklist.contains($0) }
    }
    
    struct StringLiteralCodingKey: CodingKey, ExpressibleByStringLiteral {
        var stringValue: String
        var intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init(stringLiteral: String) {
            self.stringValue = stringLiteral
        }
        
        init(intValue: Int) {
            stringValue = intValue.description
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if visited.contains(self) {
            switch self {
            case let array as NSArray:
                if array.allSatisfy({ $0 is String || $0 is NSString || $0 is NSMutableString || $0 is NSNumber || ($0 as? NSObject)?.className == "CNLabeledValue" }) {
                    break
                }
                
                fallthrough
            default:
                var container = encoder.singleValueContainer()
                try container.encode("<Circular reference to \(debugDescription)>")
                return
            }
        }
        
        switch self {
        case is DispatchData:
            var container = encoder.singleValueContainer()
            try container.encode("DispatchData")
            return
        default:
            break
        }
        
        switch self {
        case is NSString, is NSMutableString, is NSNumber:
            break
        default:
            if className == "CNLabeledValue" {
                break
            }
            
            visited.insert(self)
        }
        
        switch self {
        case let number as NSNumber:
            var container = encoder.singleValueContainer()
            try container.encode(number.doubleValue)
        case let string as NSString:
            var container = encoder.singleValueContainer()
            try container.encode(string as String)
        case let string as NSMutableString:
            var container = encoder.singleValueContainer()
            try container.encode(string as String)
        case let dictionary as NSDictionary:
            var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
            
            for key in dictionary.allKeys {
                try container.encodeIfPresent((dictionary[key] as? Encodable).map(EncodingBox.init(encodable:)), forKey: .init(stringValue: String(describing: key)))
            }
        case let dictionary as NSMutableDictionary:
            var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
            
            for key in dictionary.allKeys {
                try container.encodeIfPresent((dictionary[key] as? Encodable).map(EncodingBox.init(encodable:)), forKey: .init(stringValue: String(describing: key)))
            }
        case let array as NSArray:
            var container = encoder.unkeyedContainer()
            
            for element in array {
                if let encodable = element as? Encodable {
                    try container.encode(EncodingBox(encodable: encodable))
                } else {
                    try container.encodeNil()
                }
            }
        case let url as NSURL:
            var container = encoder.singleValueContainer()
            try container.encode(url.absoluteString)
        case let date as NSDate:
            var container = encoder.singleValueContainer()
            try container.encode(date.debugDescription)
        case let array as NSMutableArray:
            var container = encoder.unkeyedContainer()
            
            for element in array {
                if let encodable = element as? Encodable {
                    try container.encode(EncodingBox(encodable: encodable))
                } else {
                    try container.encodeNil()
                }
            }
        default:
            var container = encoder.container(keyedBy: StringLiteralCodingKey.self)
            
            var properties = properties
            
            var result: Any?
            switch self {
            case let contact as CNContact:
                properties = properties.filter(contact.isKeyAvailable(_:))
            default:
                break
            }
            
            let valueForKey = value(forKey:)
            for key in properties {
                do {
                    try ObjC.catchException {
                        result = valueForKey(key)
                    }
                } catch {
                    try container.encodeNil(forKey: .init(stringValue: key))
                    continue
                }
                
                if let object = result as? NSObject, visited.contains(object) {
                    try container.encode("Circular reference to \(object.debugDescription)", forKey: .init(stringValue: key))
                    continue
                }
                
                try container.encodeIfPresent((result as? Encodable).map(EncodingBox.init(encodable:)), forKey: .init(stringValue: key))
            }
        }
    }
}

class QueryCommand: EphemeralBarcelonaCommand {
    let name = "query"
    
    @Param var path: String
    
    @CollectedParam var subpath: [String]
    
    enum BasePath: String {
        case iMessageAccount = "account.imessage"
        case smsAccount = "account.sms"
        case handles
        case chats
        
        func eat(subpath: String) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            func send(_ value: NSObject) {
                if subpath.count == 0 {
                    return print(String(decoding: try! encoder.encode(value), as: UTF8.self))
                }
                
                if let encodable = value.value(forKeyPath: subpath) as? Encodable {
                    print(String(decoding: try! encoder.encode(EncodingBox(encodable: encodable)), as: UTF8.self))
                } else {
                    print("Unknown keypath \(subpath)")
                }
            }
            
            switch self {
            case .iMessageAccount:
                send(IMAccountController.shared.iMessageAccount!)
            case .smsAccount:
                if let account = IMAccountController.shared.activeSMSAccount {
                    send(account)
                } else {
                    print("No SMS account found")
                }
            case .handles:
                send(IMHandleRegistrar.sharedInstance().allIMHandles()!.collectedDictionary(keyedBy: \.id) as NSDictionary)
            case .chats:
                send(IMChatRegistry.shared.allChats.collectedDictionary(keyedBy: \.chatIdentifier) as NSDictionary)
            }
            
            visited = Set()
        }
    }
    
    func execute() throws {
        BasePath(rawValue: path)?.eat(subpath: subpath.joined(separator: "."))
    }
}
