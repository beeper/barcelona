//
//  Query.swift
//  grapple
//
//  Created by Eric Rabil on 11/24/21.
//

import Foundation
import SwiftCLI
import IMCore

public struct EncodingBox: Encodable {
    public var ref: (Encoder) throws -> ()
    
    public init(encodable: Encodable) {
        ref = encodable.encode(to:)
    }
    
    public func encode(to encoder: Encoder) throws {
        try ref(encoder)
    }
}

@_spi(EncodingBoxInternals) public var visited: Set<NSObject> = Set()

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
public extension NSObject {
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
    
    private var properties: [String] {
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
                var container = encoder.singleValueContainer()
                try container.encode("<Circular reference to \(debugDescription)>")
                return
            case let dict as NSDictionary:
                if dict.allValues.allSatisfy({ $0 is String || $0 is NSString || $0 is NSMutableString || $0 is NSNumber || ($0 as? NSObject)?.className == "CNLabeledValue" }) {
                    break
                }
                var container = encoder.singleValueContainer()
                try container.encode("<Circular reference to \(debugDescription)>")
                return
            case is NSDate, is NSString, is NSNumber, is NSValue:
                break
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
            
            var result: Any?

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
                    switch object {
                    case is NSDate, is NSString, is NSNumber, is NSValue:
                        break
                    case let array as NSArray:
                        if array.allSatisfy({ $0 is String || $0 is NSString || $0 is NSMutableString || $0 is NSNumber || ($0 as? NSObject)?.className == "CNLabeledValue" }) {
                            break
                        }
                        try container.encode("Circular reference to \(object.debugDescription)", forKey: .init(stringValue: key))
                        continue
                    case let dict as NSDictionary:
                        if dict.allValues.allSatisfy({ $0 is String || $0 is NSString || $0 is NSMutableString || $0 is NSNumber || ($0 as? NSObject)?.className == "CNLabeledValue" }) {
                            break
                        }
                        try container.encode("Circular reference to \(object.debugDescription)", forKey: .init(stringValue: key))
                        continue
                    default:
                        try container.encode("Circular reference to \(object.debugDescription)", forKey: .init(stringValue: key))
                        continue
                    }
                }
                
                try container.encodeIfPresent((result as? Encodable).map(EncodingBox.init(encodable:)), forKey: .init(stringValue: key))
            }
        }
    }
}
