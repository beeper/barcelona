//
//  XPCType.swift
//  SwiftXPC
//
//  Created by JP Simard on 10/29/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//  https://raw.githubusercontent.com/jpsim/SwiftXPC/1242114f0bdcf7411aac18088464fcec7ec92da3/SwiftXPC/XPCType.swift
//

import Foundation

/// Protocol to group Swift/Objective-C types that can be represented as XPC types.
public protocol XPCRepresentable {
    func isEqualTo(_ rhs: XPCRepresentable) -> Bool
}

public extension XPCRepresentable {
    var intValue: Int? {
        switch self {
        case let int64 as Int64:
            return Int(int64)
        case let uint64 as UInt64:
            return Int(uint64)
        case let int as Int:
            return int
        default:
            return nil
        }
    }
}

extension Array: XPCRepresentable {}
extension Dictionary: XPCRepresentable {}
extension String: XPCRepresentable {}
extension Date: XPCRepresentable {}
extension Data: XPCRepresentable {}
extension UInt64: XPCRepresentable {}
extension Int64: XPCRepresentable {}
extension Int: XPCRepresentable {}
extension Double: XPCRepresentable {}
extension Bool: XPCRepresentable {}
extension FileHandle: XPCRepresentable {}
extension CFBoolean: XPCRepresentable {}
extension UUID: XPCRepresentable {}
extension Optional: XPCRepresentable where Wrapped: XPCRepresentable {}

/// Possible XPC types
public enum XPCType {
    case array, dictionary, string, date, data, uInt64, int64, double, bool, fileHandle, uuid, null
    
    var type: xpc_type_t {
        typeMap.first {
            $0.value == self
        }!.key
    }
}

/// Map xpc_type_t (COpaquePointer's) to their appropriate XPCType enum value.
let typeMap: [xpc_type_t: XPCType] = [
    // FIXME: Use xpc_type_t constants as keys once http://openradar.me/19776929 has been fixed.
    xpc_get_type(xpc_array_create(nil, 0)): .array,
    xpc_get_type(xpc_dictionary_create(nil, nil, 0)): .dictionary,
    xpc_get_type(xpc_string_create("")): .string,
    xpc_get_type(xpc_date_create(0)): .date,
    xpc_get_type(xpc_data_create(UnsafeMutableRawPointer.allocate(byteCount: 0, alignment: 0), 0)): .data,
    xpc_get_type(xpc_uint64_create(0)): .uInt64,
    xpc_get_type(xpc_int64_create(0)): .int64,
    xpc_get_type(xpc_double_create(0)): .double,
    xpc_get_type(xpc_bool_create(true)): .bool,
    xpc_get_type(xpc_fd_create(0)!): .fileHandle,
    xpc_get_type(xpc_uuid_create([UInt8](repeating: 0, count: 16))): .uuid,
    xpc_get_type(xpc_null_create()): .null
]

/// Type alias to simplify referring to an Array of XPCRepresentable objects.
public typealias XPCArray = [XPCRepresentable]
/// Type alias to simplify referring to a Dictionary of XPCRepresentable objects with String keys.
public typealias XPCDictionary = [String: XPCRepresentable]

/// Enable comparison of XPCRepresentable objects.
extension XPCRepresentable {
    public func isEqualTo(_ rhs: XPCRepresentable) -> Bool {
        switch self {
        case let lhs as XPCArray:
            for (idx, value) in lhs.enumerated() {
                if let rhs = rhs as? XPCArray, rhs[idx].isEqualTo(value) {
                    continue
                }
                return false
            }
            return true
        case let lhs as XPCDictionary:
            for (key, value) in lhs {
                if let rhs = rhs as? XPCDictionary,
                    let rhsValue = rhs[key], rhsValue.isEqualTo(value) {
                        continue
                }
                return false
            }
            return true
        case let lhs as String:
            return lhs == rhs as? String
        case let lhs as Date:
            return (rhs as? Date).map { rhs in
                return abs(lhs.timeIntervalSince(rhs)) < 0.000001
                } ?? false
        case let lhs as Data:
            return lhs == rhs as? Data
        case let lhs as UInt64:
            return lhs == rhs as? UInt64
        case let lhs as Int64:
            return lhs == rhs as? Int64
        case let lhs as Double:
            return lhs == rhs as? Double
        case let lhs as Bool:
            return lhs == rhs as? Bool
        case let lhs as FileHandle:
            return ((rhs as? FileHandle)?.fileDescriptor).map { rhsFD in
                let lhsFD = lhs.fileDescriptor
                var lhsStat = stat(), rhsStat = stat()
                if (fstat(lhsFD, &lhsStat) < 0 ||
                    fstat(rhsFD, &rhsStat) < 0) {
                        return false
                }
                return (lhsStat.st_dev == rhsStat.st_dev) && (lhsStat.st_ino == rhsStat.st_ino)
                } ?? false
        case let lhs as UUID:
            return (lhs == (rhs as? UUID))
        default:
            // Should never happen because we've checked all XPCRepresentable types
            return false
        }
    }
}
