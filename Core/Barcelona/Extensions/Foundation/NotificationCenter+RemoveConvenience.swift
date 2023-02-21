//
//  NotificationCenter+RemoveConvenience.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/27/21.
//

import Foundation

extension NotificationCenter {
    public func addObserver(
        forName name: NSNotification.Name?,
        object obj: Any?,
        queue: OperationQueue?,
        using block: @escaping (Notification, () -> Void) -> Void
    ) {
        var observer: NSObjectProtocol?

        func unsubscribe() {
            if observer != nil {
                NotificationCenter.default.removeObserver(observer!)
                observer = nil
            }
        }

        observer = NotificationCenter.default.addObserver(forName: name, object: obj, queue: queue) { notification in
            block(notification, unsubscribe)
        }
    }
}
