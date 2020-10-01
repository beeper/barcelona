//
//  ChatResourceMiddleware.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Contacts
import IMCore
import Vapor
import SwiftJWT

//enum ResourceParameterKeys: String {
//    case chatID
//    case messageID
//    case attachmentID
//    case serviceID
//}

let IMChatResourceKey = "chatID"
let IMMultiChatResourceKey = "chatIDs"
let IMMessageResourceKey = "messageID"
let CNContactResourceKey = "contactID"
let AttachmentResourceKey = "attachmentID"
let IMServiceResourceKey = "serviceID"

private let IMChatResolver = createResolver(clazz: IMChat.self, parameterKey: IMChatResourceKey)
let IMChatMiddleware = IMChatResolver.middleware
let IMChatStorageKey = IMChatResolver.storageKey

private let IMMessageResolver = createLazyResolver(clazz: IMMessage.self, parameterKey: IMMessageResourceKey)
let IMMessageMiddleware = IMMessageResolver.middleware
let IMMessageStorageKey = IMMessageResolver.storageKey

private let CNContactResolver = createResolver(clazz: CNContact.self, parameterKey: CNContactResourceKey)
let CNContactMiddleware = CNContactResolver.middleware
let CNContactStorageKey = CNContactResolver.storageKey

private let MessageResolver = createLazyResolver(clazz: Message.self, parameterKey: IMMessageResourceKey)
let MessageMiddleware = MessageResolver.middleware
let MessageStorageKey = MessageResolver.storageKey

private let AttachmentResolver = createLazyResolver(clazz: InternalAttachment.self, parameterKey: AttachmentResourceKey)
let AttachmentMiddleware = AttachmentResolver.middleware
let AttachmentStorageKey = AttachmentResolver.storageKey

private let IMServiceResolver = createResolver(clazz: IMService.self, parameterKey: IMServiceResourceKey)
let IMServiceMiddleware = IMServiceResolver.middleware
let IMServiceStorageKey = IMServiceResolver.storageKey

let JWTStorageKey = ResolvableStorageKey<JWT<JWTClaim>>.self
