//
//  XPC.swift
//  Barcelona
//
//  Created by June Welker on 4/4/23.
//

import Foundation

extension OS_xpc_object {
    func toSwift() -> Any {
        if let dict = toSwiftDictionary() {
            return dict
        } else if let str = toSwiftString() {
            return str
        } else if let date = toSwiftDate() {
            return date
        } else if let arr = toSwiftArray() {
            return arr
        } else if let data = toSwiftData() {
            return data
        } else if let uint = toSwiftUInt64() {
            return uint
        } else if let int = toSwiftInt64() {
            return int
        } else if let double = toSwiftDouble() {
            return double
        } else if let bool = toSwiftBool() {
            return bool
        } else if let handle = toSwiftFileHandle() {
            return handle
        }
        // So that we don't lose data if it can't be mapped for whatever reason
        return self
    }

    func toSwiftDictionary() -> [String: Any]? {
        if xpc_get_type(self) != XPC_TYPE_DICTIONARY {
            return nil
        }

        var retVal: [String: Any] = .init(minimumCapacity: xpc_dictionary_get_count(self))

        _ = xpc_dictionary_apply(self) { key, val in
            if let swiftKey = String(validatingUTF8: key) {
                retVal[swiftKey] = val.toSwift()
            }
            return true
        }

        return retVal
    }

    func toSwiftString() -> String? {
        if xpc_get_type(self) != XPC_TYPE_STRING {
            return nil
        }

        return xpc_string_get_string_ptr(self).flatMap {
            String(validatingUTF8: $0)
        }
    }

    func toSwiftDate() -> Date? {
        if xpc_get_type(self) != XPC_TYPE_DATE {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(xpc_date_get_value(self)) / 1000000000)
    }

    func toSwiftArray() -> [Any]? {
        if xpc_get_type(self) != XPC_TYPE_ARRAY {
            return nil
        }

        var arr = [Any]()
        _ = xpc_array_apply(self) { idx, obj in
            arr.append(obj.toSwift())
            return true
        }
        return arr
    }

    func toSwiftData() -> Data? {
        if xpc_get_type(self) != XPC_TYPE_DATA {
            return nil
        }

        return xpc_data_get_bytes_ptr(self).map {
            Data(bytes: $0, count: Int(xpc_data_get_length(self)))
        }
    }

    func toSwiftUInt64() -> UInt64? {
        if xpc_get_type(self) != XPC_TYPE_UINT64 {
            return nil
        }

        return xpc_uint64_get_value(self)
    }

    func toSwiftInt64() -> Int64? {
        if xpc_get_type(self) != XPC_TYPE_INT64 {
            return nil
        }

        return xpc_int64_get_value(self)
    }

    func toSwiftDouble() -> Double? {
        if xpc_get_type(self) != XPC_TYPE_DOUBLE {
            return nil
        }

        return xpc_double_get_value(self)
    }

    func toSwiftBool() -> Bool? {
        if xpc_get_type(self) != XPC_TYPE_BOOL {
            return nil
        }

        return xpc_bool_get_value(self)
    }

    func toSwiftFileHandle() -> FileHandle? {
        if xpc_get_type(self) != XPC_TYPE_FD {
            return nil
        }

        return FileHandle(fileDescriptor: xpc_fd_dup(self), closeOnDealloc: true)
    }
}
