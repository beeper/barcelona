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

private let IMCSChangeHistoryAddContactEventNotification = Notification.Name(rawValue: "IMCSChangeHistoryAddContactEventNotification")
private let IMCSChangeHistoryUpdateContactEventNotification = Notification.Name(rawValue: "IMCSChangeHistoryUpdateContactEventNotification")
private let IMCSChangeHistoryDeleteContactEventNotification = Notification.Name(rawValue: "IMCSChangeHistoryDeleteContactEventNotification")

private let IMCSChangeHistoryContactIdentifierKey = "__kIMCSChangeHistoryContactIdentifierKey"
private let IMCSChangeHistoryContactKey = "__kIMCSChangeHistoryContactKey"

/**
 Tracks events related to Contacts.framework
 */
public class ContactsEvents: EventDispatcher {
    override var log: Logger { Logger(category: "ContactsEvents") }
    
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
            log.error("⁉️ got contact inserted notification but didn't receive CNContact in userinfo")
            return
        }
        
        bus.dispatch(.contactCreated(Contact(contact)))
    }
    
    // MARK: - Contact updated
    private func contact(updated: Notification) {
        guard let userInfo = updated.userInfo as? [String: NSObject], let contact = userInfo[IMCSChangeHistoryContactKey] as? CNContact else {
            log.error("⁉️ got contact updated notification but didn't receive CNContact in userinfo")
            return
        }
        
        bus.dispatch(.contactUpdated(Contact(contact)))
    }
    
    // MARK: - Contact deleted
    private func contact(deleted: Notification) {
        guard let userInfo = deleted.userInfo as? [String: NSObject], let contactID = userInfo[IMCSChangeHistoryContactIdentifierKey] as? String else {
            log.error("⁉️ got contact deleted notification but didn't receive String in userinfo")
            return
        }
        
        bus.dispatch(.contactRemoved(contactID))
    }
}
