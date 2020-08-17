//
//  ERIndeterminateIngestor.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

private let TranscriptLikeClasses = [
    IMTranscriptChatItem.self,
    IMGroupTitleChangeItem.self,
    IMParticipantChangeItem.self,
    IMGroupTitleChangeChatItem.self,
    IMGroupActionItem.self
]

private let ChatLikeClasses = [
    IMAttachmentMessagePartChatItem.self,
    IMTranscriptPluginChatItem.self,
    IMTextMessagePartChatItem.self,
    IMMessageAcknowledgmentChatItem.self,
    IMAssociatedMessageItem.self,
    IMMessage.self,
    IMMessageItem.self
]

public typealias ClassParserFunc<T: AnyObject> = (T, EventLoop) -> EventLoopFuture<ChatItem?>?

public struct ClassParser<T: AnyObject> {
    var clazz: T
    var parse: ClassParserFunc<T>
}

struct ERIndeterminateIngestor {
    private static var transcriptLikeParsers: [ClassParser<NSObject>] = []
    private static var chatLikeParsers: [ClassParser<NSObject>] = []
    
    public static func ingest(_ object: AnyObject, on eventLoop: EventLoop) -> EventLoopFuture<ChatItem?> {
        let promise = eventLoop.makePromise(of: ChatItem?.self)
        
        if TranscriptLikeClasses.contains(where: { object.isKind(of: $0) }) {
            
        }
        
        if ChatLikeClasses.contains(where: { object.isKind(of: $0) }) {
            
        }
        
        return promise.futureResult
    }
    
    public static func ingest(_ objects: [AnyObject], on eventLoop: EventLoop) -> EventLoopFuture<[ChatItem]> {
        EventLoopFuture<ChatItem?>.whenAllSucceed(objects.map {
            self.ingest($0, on: eventLoop)
        }, on: eventLoop).map {
            $0.compactMap { $0 }
        }
    }
    
    public static func registerTranscriptLike<T: AnyObject>(_ class: T, transformer: ClassParserFunc<T>) {
        
    }
    
    public static func registerChatLike<T: AnyObject>(_ class: T, transformer: ClassParserFunc<T>) {
        
    }
}
