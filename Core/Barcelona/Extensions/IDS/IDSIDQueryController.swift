//
//  IDSIDQueryController.swift
//  Barcelona
//
//  Created by June Welker on 3/6/23.
//

import Foundation
import IDS
import CommonUtilities

@objc public protocol InternalQueryController: NSObjectProtocol {
    // The NSDictionary in the result should be of type [String: Int64]
    @available(macOS 13.0, *)
    @objc func _idStatus(forDestinations: NSArray, service: String, listenerID: String, allowRenew: Bool, respectExpiry: Bool, waitForReply: Bool, forceRefresh: Bool, bypassLimit: Bool, completionBlock: @escaping (CUTResult<NSDictionary>) -> ())

}

public extension IDSIDQueryController {
    // This is a way of exposing self._internal, which is actually of type
    // _IDSIDQueryController, but that type's interface is not exposed in a way
    // that we can link to (it doesn't have a _OBJC_CLASS_$_... symbol for that
    // class), so we just make this protocol and use these memory tricks to work
    // around it.
    var internalController: InternalQueryController? {
        guard var intern = self.value(forKey: "_internal") else {
            return nil
        }

        // Credits to https://forums.swift.org/t/unsafebitcast-to-unimplemented-class/5079/2
        return withUnsafePointer(to: &intern) {
            $0.withMemoryRebound(to: InternalQueryController.self, capacity: 1) {
                $0.pointee
            }
        }
    }
}
