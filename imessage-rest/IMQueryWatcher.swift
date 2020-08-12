//
//  IMEventReceiver.swift
//  imessage-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

private let queryKey = "__kIMChatQueryIDKey";
private let IMChatLoadRequestDidCompleteNotification = NSNotification.Name(rawValue: "__kIMChatLoadRequestDidCompleteNotification")

/**
 Watches for the completion of a query and allows code to register a callback for a given query GUID
 */
class IMQueryWatcher {
    static let sharedInstance = IMQueryWatcher();
    
    private init() {
        NotificationCenter.default.addObserver(forName: IMChatLoadRequestDidCompleteNotification, object: nil, queue: nil) {
            self.queryCompleted($0)
        }
    }
    
    private var queryObservers: [String: NSObjectProtocol] = [:];
    
    private func registerObserver(queryID: String, observer: NSObjectProtocol) {
        DispatchQueue.main.async {
            self.queryObservers[queryID] = observer
        }
    }
    
    private func deregisterObserver(queryID: String) {
        DispatchQueue.main.async {
            guard let observer = self.queryObservers[queryID] else { return }
            self.queryObservers.removeValue(forKey: queryID)
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /** Registers a callback for a given query GUID */
    func waitForQuery(queryID: String, callback: @escaping (NSNotification) -> ()) {
        let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "IMCQ-COMPLETE-\(queryID)"), object: nil, queue: OperationQueue.current ?? OperationQueue.main) { notif in
            callback(notif as NSNotification)
            self.deregisterObserver(queryID: queryID)
        }
        
        self.registerObserver(queryID: queryID, observer: observer)
    }
    
    /** Called when a query has completed */
    func queryCompleted(_ notification: Notification) {
        guard let query = notification.userInfo?[queryKey] as? String else { return }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "IMCQ-COMPLETE-\(query)"), object: nil)
    }
}
