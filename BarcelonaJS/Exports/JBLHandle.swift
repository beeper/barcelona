//
//  JBLHandle.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona
import IMCore

@objc
public protocol JBLAccountJSExports: JSExport {
    static var accounts: [JBLAccountJSExports] { get }
    
    var id: String { get }
    var service: String { get }
    var active: Bool { get }
    var connected: Bool { get }
    var rawDescription: String { get }
    var loginHandle: String { get }
    var handles: [String] { get }
}

@objc
public class JBLAccount: NSObject, JBLAccountJSExports {
    public static var accounts: [JBLAccountJSExports] {
        Registry.sharedInstance.allAccounts.map(JBLAccount.init(account:))
    }
    
    public init(account: IMAccount) {
        id = account.uniqueID
    }
    
    internal var account: IMAccount { Registry.sharedInstance.account(withUniqueID: id) }
    
    public var id: String
    public var service: String { account.serviceName }
    public var active: Bool { account.isActive }
    public var connected: Bool { account.isConnected }
    public var rawDescription: String { account.description }
    public var loginHandle: String { account.login }
    public var handles: [String] { account.aliases }
}

@objc
public protocol JBLContactJSExports: JSExport {
    static var contacts: [JBLContactJSExports] { get }
    static func contactsWithHandleID(_ handleID: String) -> [JBLContactJSExports]
    
    var id: String { get }
    var handles: [String] { get }
    var name: String { get }
}

@objc
public class JBLContact: NSObject, JBLContactJSExports {
    public static var contacts: [JBLContactJSExports] {
        IMContactStore.sharedInstance()!.allContacts.map(Contact.init).map(JBLContact.init)
    }
    
    public static func contactsWithHandleID(_ handleID: String) -> [JBLContactJSExports] {
        Contact.resolveSync(withParameters: .init(handles: [handleID]))
            .map(JBLContact.init)
    }
    
    public init(_ contact: Contact) {
        self.contact = contact
    }
    
    internal let contact: Contact
    
    public var id: String { contact.id }
    public var name: String { contact.fullName ?? "" }
    public var handles: [String] { contact.handles.map(\.id) }
}
