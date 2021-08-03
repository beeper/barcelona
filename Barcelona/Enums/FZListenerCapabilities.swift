//
//  FZListenerCapabilities.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public enum FZListenerCapabilities: UInt32 {
    case Status = 1
    case Notifications = 2
    case Chats = 4
    case VC = 8
    case AVChatInfo = 16
    case AuxInput = 32
    case VCInvitations = 64
    case Lega = 128
    case Transfers = 256
    case Accounts = 512
    case BuddyList = 1024
    case ChatObserver = 2048
    case SendMessages = 4096
    case MessageHistory = 8192
    case IDQueries = 16384
    case ChatCounts = 32768
    
    static var defaults: [FZListenerCapabilities] = [
        .Status, .Notifications, .Chats, .Lega, .Transfers, .Accounts, .BuddyList, .ChatObserver, .SendMessages, .MessageHistory, .IDQueries, .ChatCounts
    ]
    
    static var defaults_: UInt32 {
        defaults.map(\.rawValue).reduce(into: 0, |=)
    }
}
