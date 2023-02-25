//
//  NSObject.swift
//  Barcelona
//
//  Created by June on 1/24/23.
//

import Foundation

// This should only be used to debug objects whose selectors are being confusing, shouldn't be used in prod
#if DEBUG
extension NSObjectProtocol {
    public var methodList: [String]? {
        var mc: UInt32 = 0
        let mcPointer = withUnsafeMutablePointer(to: &mc, { $0 })
        guard let mlist = class_copyMethodList(type(of: self), mcPointer) else {
            return nil
        }

        return (0...Int(mc))
            .map {
                String(format: "Method #%d: %s", arguments: [$0, sel_getName(method_getName(mlist[$0]))])
            }
    }
}

extension Protocol {
    public func methodList(requiredOnly: Bool = false, instanceOnly: Bool = false) -> [String]? {
        var count: UInt32 = 0
        let countPointer = withUnsafeMutablePointer(to: &count, { $0 })
        guard let mList = protocol_copyMethodDescriptionList(self, requiredOnly, instanceOnly, countPointer) else {
            return nil
        }

        return (0...Int(count))
            .map {
                "Method #\($0): \(sel_getName(mList[$0].name!))"
            }
    }
}
#endif
