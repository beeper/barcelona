//
//  Chat+ParticipantsAPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import os.log

private let log_participantAPI = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ParticipantAPI")

// MARK: - Participants
func bindParticipantsAPI(_ chat: RoutesBuilder) {
    let participants = chat.grouped("participants")
    
    /**
     Lookup participants of a chat
     */
    participants.get { req -> BulkHandleIDRepresentation in
        req.chat.participantIDs
    }
    
    // MARK: - Participant Management
    
    /**
     Manage the state of a set of participants
     */
    func toggleParticipants(_ add: Bool, req: Request) throws -> EventLoopFuture<BulkHandleIDRepresentation> {
        guard let chat = req.imChat, let account = chat.account else {
            throw Abort(.internalServerError, reason: "Failed to resolve chat/account combo from request")
        }
        
        /*
         {"handles":["1234","eric@net.com"]}
         */
        guard let insertion = try? req.content.decode(BulkHandleIDRepresentation.self) else {
            os_log("Got a malformed payload from client, bailing", log_participantAPI)
            throw Abort(.badRequest)
        }
        
        return req.eventLoop.submit {
            let handles = insertion.handles.compactMap { Registry.sharedInstance.imHandle(withID: $0, onAccount: account) }
            
            if add {
                if !chat.canAddParticipants(handles) {
                    os_log("Can't add participants to this chat, bailing", log_participantAPI)
                    throw Abort(.badRequest, reason: "You can't add pariticpants to this group.")
                }
                
                let reasonMessage = IMMessage.instantMessage(withText: NSAttributedString(string: "Get in my fucking van, kid."), messageSubject: nil, flags: 0x5)
                
                chat.inviteParticipantsToiMessageChat(handles, reason: reasonMessage)
            } else {
                let reasonMessage = IMMessage.instantMessage(withText: NSAttributedString(string: "Goodbye, skank."), messageSubject: nil, flags: 0x5)
                
                chat.removeParticipantsFromiMessageChat(handles, reason: reasonMessage)
            }
            
            return BulkHandleIDRepresentation(handles: chat.participantHandleIDs())
        }
    }
    
    /**
     Add participants to a chat
     */
    participants.put { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        return try toggleParticipants(true, req: req)
    }
    
    /**
     Remove participants from a chat
     */
    participants.delete { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        return try toggleParticipants(false, req: req)
    }
}

