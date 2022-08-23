////  NicknameController.swift
//  Barcelona
//
//  Created by Eric Rabil on 9/3/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

@available(macOS 10.15, iOS 13.0, *)
fileprivate var nicknames: [String: IMNickname] {
    IMNicknameController.sharedInstance()._updateLocalNicknameStore()
    
    return IMNicknameController.sharedInstance().handledNicknames
        .reduce(into: IMNicknameController.sharedInstance().pendingNicknameUpdates) {
            $0[$1.key] = $1.value
        }
}

@available(macOS 10.15, iOS 13.0, *)
fileprivate extension IMNickname {
    var avatarURL: URL? {
        guard let avatar = avatar else {
            return nil
        }
        
        return URL(fileURLWithPath: avatar.imageFilePath)
    }
    
    var imHandle: IMHandle {
        Chat.bestHandle(forID: handle)
    }
    
    var suggestionData: BLContactSuggestionData {
        BLContactSuggestionData(
            displayName: displayName, firstName: firstName, lastName: lastName, image: avatarURL, syntheticContactID: imHandle.cnContact.id
        )
    }
}

public struct BLContactSuggestionData: Codable {
    public var displayName: String?
    public var firstName: String?
    public var lastName: String?
    public var image: URL?
    public var syntheticContactID: String
}

public func BLResolveContactSuggestionData(forHandle handle: IMHandle) -> BLContactSuggestionData? {
    guard #available(macOS 10.15, iOS 13.0, *) else {
        return nil
    }
    
    return IMNicknameController.sharedInstance().nickname(for: handle)?.suggestionData
}

public func BLResolveContactSuggestionData(forHandleID handleID: String) -> BLContactSuggestionData? {
    guard #available(macOS 10.15, iOS 13.0, *) else {
        return nil
    }
    
    return nicknames[handleID]?.suggestionData
}
