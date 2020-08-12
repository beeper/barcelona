//
//  AttachmentsAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

import Vapor
import Swime

public func bindAttachmentsAPI(_ app: Application) {
    let attachments = app.grouped("attachments")
    
    /**
     Create attachment
     */
    attachments.on(.POST, "", body: .stream) { req -> EventLoopFuture<AttachmentRepresentation> in
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
        isDirectory: true)

        let promise = req.eventLoop.makePromise(of: AttachmentRepresentation.self)
        var temporaryFilename = NSString.stringGUID() as! String
        
        var temporaryFileURL =
            temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        
        var mime: MimeType? = nil
        var bytes: Int = 0
        
        req.application.fileio.openFile(path: temporaryFileURL.path, mode: .write, flags: .allowFileCreation(), eventLoop: req.eventLoop).flatMap { fileHandle -> EventLoopFuture<Void> in
            let promise = req.eventLoop.makePromise(of: Void.self)
            
            // MARK: - Upload phase
            
            var first: Bool = true
            req.body.drain { part in
                switch part {
                case .buffer(let buffer):
                    if first {
                        first = false
                        if let data = buffer.getData(at: 0, length: buffer.readableBytes) {
                            mime = Swime.mimeType(data: data)
                        }
                    }
                    bytes += buffer.readableBytes
                    return req.application.fileio.write(fileHandle: fileHandle, buffer: buffer, eventLoop: req.eventLoop)
                case .error(_):
                    do {
                        try fileHandle.close()
                        promise.fail(Abort(.internalServerError))
                    } catch {
                        promise.fail(Abort(.internalServerError))
                    }
                case .end:
                    do {
                        try fileHandle.close()
                        promise.succeed(())
                    } catch {
                        promise.fail(Abort(.internalServerError))
                    }
                }
                return req.eventLoop.makeSucceededFuture(())
            }
            
            return promise.futureResult
        }.always { _ in
            
            // MARK: - Storage phase
            
            let center = IMFileTransferCenter.sharedInstance()!
            
            if let mime = mime {
                let guid = temporaryFilename
                temporaryFilename = "\(temporaryFilename).\(mime.ext)"
                let newURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
                try! FileManager.default.moveItem(at: temporaryFileURL, to: newURL)
                
                print(newURL.isFileURL)
                
                let transfer = IMFileTransfer()._init(withGUID: guid, filename: temporaryFilename, isDirectory: false, localURL: newURL, account: Registry.sharedInstance.iMessageAccount()!.uniqueID, otherPerson: nil, totalBytes: UInt64(bytes), hfsType: 0, hfsCreator: 0, hfsFlags: 0, isIncoming: false)!
                transfer.setValue(mime.mime, forKey: "_mimeType")
                transfer.setValue(IMFileManager.defaultHFS()!.utiType(ofMimeType: mime.mime), forKey: "_utiType")
                
                // MARK: - Transfer registration and completion
                
                center._addTransfer(transfer, toAccount: Registry.sharedInstance.iMessageAccount()!.uniqueID)
                
                if let map = center.value(forKey: "_guidToTransferMap") as? NSDictionary {
                    map.setValue(transfer, forKey: guid)
                    
                    center.registerTransfer(withDaemon: guid)
                }
                
                promise.succeed(AttachmentRepresentation(transfer))
            }
        }
        
        return promise.futureResult
    }
    
    let attachment = attachments.grouped(":guid")
    
    /**
     Get attachment
     */
    attachment.get { req -> EventLoopFuture<Response> in
        guard let guid = req.parameters.get("guid") else { throw Abort(.badRequest) }
        guard let file = IMFileTransferCenter.sharedInstance()?.transfer(forGUID: guid, includeRemoved: false) else { throw Abort(.notFound) }
        guard let path = file.localPath else { throw Abort(.notFound) }
        guard file.existsAtLocalPath else { throw Abort(.notFound) }
        
        return req.eventLoop.makeSucceededFuture(req.fileio.streamFile(at: path))
    }
}
