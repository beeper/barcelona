//
//  ContactsEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import Contacts
import os.log

private let log_contactEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ContactsEvents")

private let IMCSChangeHistoryAddContactEventNotification = Notification.Name(rawValue: "IMCSChangeHistoryAddContactEventNotification")
private let IMCSChangeHistoryUpdateContactEventNotification = Notification.Name(rawValue: "IMCSChangeHistoryUpdateContactEventNotification")
private let IMCSChangeHistoryDeleteContactEventNotification = Notification.Name(rawValue: "IMCSChangeHistoryDeleteContactEventNotification")

private let IMCSChangeHistoryContactIdentifierKey = "__kIMCSChangeHistoryContactIdentifierKey"
private let IMCSChangeHistoryContactKey = "__kIMCSChangeHistoryContactKey"

/**
 Tracks events related to Contacts.framework
 */
public class ContactsEvents: EventDispatcher {
    public override func wake() {
        addObserver(forName: IMCSChangeHistoryAddContactEventNotification) {
            self.contact(inserted: $0)
        }
        
        addObserver(forName: IMCSChangeHistoryUpdateContactEventNotification) {
            self.contact(updated: $0)
        }
        
        addObserver(forName: IMCSChangeHistoryDeleteContactEventNotification) {
            self.contact(deleted: $0)
        }
    }
    
    // MARK: - Contact created
    private func contact(inserted: Notification) {
        guard let userInfo = inserted.userInfo as? [String: NSObject], let contact = userInfo[IMCSChangeHistoryContactKey] as? CNContact else {
            os_log("⁉️ got contact inserted notification but didn't receive CNContact in userinfo", type: .error, log_contactEvents)
            return
        }
        
        bus.dispatch(.contactCreated(Contact(contact)))
    }
    
    // MARK: - Contact updated
    private func contact(updated: Notification) {
        guard let userInfo = updated.userInfo as? [String: NSObject], let contact = userInfo[IMCSChangeHistoryContactKey] as? CNContact else {
            os_log("⁉️ got contact updated notification but didn't receive CNContact in userinfo", type: .error, log_contactEvents)
            return
        }
        
        bus.dispatch(.contactUpdated(Contact(contact)))
    }
    
    // MARK: - Contact deleted
    private func contact(deleted: Notification) {
        guard let userInfo = deleted.userInfo as? [String: NSObject], let contactID = userInfo[IMCSChangeHistoryContactIdentifierKey] as? String else {
            os_log("⁉️ got contact deleted notification but didn't receive String in userinfo",  type: .error, log_contactEvents)
            return
        }
        
        bus.dispatch(.contactRemoved(contactID))
    }
}
