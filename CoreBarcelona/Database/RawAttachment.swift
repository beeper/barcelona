//
//  RawAttachment.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log
import GRDB
import NIO

class RawAttachment: Record {
    override class var databaseTableName: String { "attachment" }
    
    static let messageAttachmentJoin = belongsTo(MessageAttachmentJoin.self, using: ForeignKey(["ROWID"], to: ["attachment_id"]))
    
    required init(row: Row) {
        ROWID = row[Columns.ROWID]
        guid = row[Columns.guid]
        created_date = row[Columns.created_date]
        start_date = row[Columns.start_date]
        filename = row[Columns.filename]
        uti = row[Columns.uti]
        mime_type = row[Columns.mime_type]
        transfer_state = row[Columns.transfer_state]
        is_outgoing = row[Columns.is_outgoing]
        user_info = row[Columns.user_info]
        transfer_name = row[Columns.transfer_name]
        total_bytes = row[Columns.total_bytes]
        is_sticker = row[Columns.is_sticker]
        sticker_user_info = row[Columns.sticker_user_info]
        attribution_info = row[Columns.attribution_info]
        hide_attachment = row[Columns.hide_attachment]
        ck_sync_state = row[Columns.ck_sync_state]
        ck_server_change_token_blob = row[Columns.ck_server_change_token_blob]
        ck_record_id = row[Columns.ck_record_id]
        original_guid = row[Columns.original_guid]
        sr_ck_sync_state = row[Columns.sr_ck_sync_state]
        sr_ck_server_change_token_blob = row[Columns.sr_ck_server_change_token_blob]
        sr_ck_record_id = row[Columns.sr_ck_record_id]
        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.ROWID] = ROWID
        container[Columns.guid] = guid
        container[Columns.created_date] = created_date
        container[Columns.start_date] = start_date
        container[Columns.filename] = filename
        container[Columns.uti] = uti
        container[Columns.mime_type] = mime_type
        container[Columns.transfer_state] = transfer_state
        container[Columns.is_outgoing] = is_outgoing
        container[Columns.user_info] = user_info
        container[Columns.transfer_name] = transfer_name
        container[Columns.total_bytes] = total_bytes
        container[Columns.is_sticker] = is_sticker
        container[Columns.sticker_user_info] = sticker_user_info
        container[Columns.attribution_info] = attribution_info
        container[Columns.hide_attachment] = hide_attachment
        container[Columns.ck_sync_state] = ck_sync_state
        container[Columns.ck_server_change_token_blob] = ck_server_change_token_blob
        container[Columns.ck_record_id] = ck_record_id
        container[Columns.original_guid] = original_guid
        container[Columns.sr_ck_sync_state] = sr_ck_sync_state
        container[Columns.sr_ck_server_change_token_blob] = sr_ck_server_change_token_blob
        container[Columns.sr_ck_record_id] = sr_ck_record_id
    }

    enum Columns: String, ColumnExpression {
        case ROWID, guid, created_date, start_date, filename, uti, mime_type, transfer_state, is_outgoing, user_info, transfer_name, total_bytes, is_sticker, sticker_user_info, attribution_info, hide_attachment, ck_sync_state, ck_server_change_token_blob, ck_record_id, original_guid, sr_ck_sync_state, sr_ck_server_change_token_blob, sr_ck_record_id
    }

    var ROWID: Int64?
    var guid: String?
    var created_date: Int64?
    var start_date: Int64?
    var filename: String?
    var uti: String?
    var mime_type: String?
    var transfer_state: Int64?
    var is_outgoing: Int64?
    var user_info: Data?
    var transfer_name: String?
    var total_bytes: Int64?
    var is_sticker: Int64?
    var sticker_user_info: Data?
    var attribution_info: Data?
    var hide_attachment: Int64?
    var ck_sync_state: Int64?
    var ck_server_change_token_blob: Data?
    var ck_record_id: String?
    var original_guid: String?
    var sr_ck_sync_state: Int64?
    var sr_ck_server_change_token_blob: Data?
    var sr_ck_record_id: String?
    
    /// Constructs an internal attachment representation centered around a resource origin
    /// - Parameter origin: origin to pass to the internal attachment
    /// - Returns: an internal attachment object
    func internalAttachment(withOrigin origin: ResourceOrigin? = nil) -> InternalAttachment? {
        guard let guid = guid, let path = filename as NSString? else {
            return nil
        }
        
        return InternalAttachment(guid: guid, originalGUID: original_guid, path: path.expandingTildeInPath, bytes: UInt64(total_bytes ?? 0), incoming: (is_outgoing ?? 0) == 0, mime: mime_type, uti: uti, origin: origin)
    }
    
    var internalAttachment: InternalAttachment? {
        internalAttachment()
    }
}

extension DBReader {
    func attachment(for guid: String) -> EventLoopFuture<InternalAttachment?> {
        return attachments(withGUIDs: [guid]).map {
            $0.first
        }
    }
    
    func attachments(withGUIDs guids: [String]) -> EventLoopFuture<[InternalAttachment]> {
        os_log("DBReader selecting attachments with GUIDs %@", guids)
        
        if guids.count == 0 { return eventLoop.makeSucceededFuture([]) }
        
        if ERBarcelonaManager.isSimulation {
            return eventLoop.makeSucceededFuture(guids.compactMap { guid in
                IMFileTransferCenter.sharedInstance()?.transfer(forGUID: guid, includeRemoved: false)?.internalAttachment
            })
        }
        
        let promise = eventLoop.makePromise(of: [InternalAttachment].self)
        
        pool.asyncRead { result in
            switch result {
            case .failure(let error):
                promise.fail(error)
            case .success(let db):
                do {
                    
                    let results = try RawAttachment.filter(guids.contains(RawAttachment.Columns.guid) || guids.contains(RawAttachment.Columns.original_guid)).fetchAll(db)
                    
                    let transfers = results.compactMap { result -> InternalAttachment? in
                        result.internalAttachment
                    }

                    promise.succeed(transfers)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
}
