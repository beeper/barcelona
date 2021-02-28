//
//  AttachmentsAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import IMCore
import IMSharedUtilities
import IMDPersistence
import Vapor
import Swime

private extension InternalAttachment {
    var type: HTTPMediaType {
        guard let parts = mime?.split(separator: "/"), let mediaType = parts.first, let mediaSubtype = parts.last else {
            return .any
        }
        
        return .init(type: String(mediaType), subType: String(mediaSubtype))
    }
}

internal func bindAttachmentsAPI(_ builder: RoutesBuilder, readAuthorizedBuilder: RoutesBuilder) {
    let attachments = builder.grouped("attachments")
    let readAuthorizedAttachments = readAuthorizedBuilder.grouped("attachments")
    
    /**
     Create attachment
     */
    attachments.on(.POST, "", body: .stream) { req -> EventLoopFuture<Attachment> in
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
        isDirectory: true)
        
        let promise = req.eventLoop.makePromise(of: Attachment.self)
        var temporaryFilename = NSString.stringGUID()
        
        var temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        
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
        }.whenComplete { result in
            
            switch result {
            case .failure(let error):
                promise.fail(error)
                return
            case .success:
                break
            }
            
            // MARK: - Storage phase
            
            let center = IMFileTransferCenter.sharedInstance()!
        
            let guid = temporaryFilename
            
            let mime = mime ?? MimeType.all.first(where: {
                $0.ext == req.headers.contentType?.subType
            })
            
            if let mime = mime {
                temporaryFilename = "\(temporaryFilename).\(mime.ext)"
                
                let newURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
                try! FileManager.default.moveItem(at: temporaryFileURL, to: newURL)
                
                temporaryFileURL = newURL
            }
            
            let transfer = IMFileTransfer()._init(withGUID: guid, filename: temporaryFilename, isDirectory: false, localURL: temporaryFileURL, account: Registry.sharedInstance.iMessageAccount()!.uniqueID, otherPerson: nil, totalBytes: UInt64(bytes), hfsType: 0, hfsCreator: 0, hfsFlags: 0, isIncoming: false)!
            
            
            if let mime = mime {
                transfer.setValue(mime.mime, forKey: "_mimeType")
                transfer.setValue(IMFileManager.defaultHFS()!.utiType(ofMimeType: mime.mime), forKey: "_utiType")
            }
            
            var persistentPath = IMDPersistentAttachmentController.sharedInstance()._persistentPath(for: transfer, filename: temporaryFilename, highQuality: true)
            
            #if os(macOS)
            
            let storedPath = "~/\(persistentPath!.split(separator: "/")[2...].joined(separator: "/"))"
            
            #else
            
            let storedPath = persistentPath!
            
            #endif
            
            
            if let persistentURL = URL(string: "file://\(persistentPath!)") {
                try! FileManager.default.createDirectory(at: persistentURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                
                try! FileManager.default.moveItem(at: temporaryFileURL, to: persistentURL)
                
                transfer.localURL = persistentURL
                transfer.filename = persistentURL.lastPathComponent
                transfer.transferredFilename = persistentURL.lastPathComponent
            }
            
            // MARK: - Transfer registration and completion
            
            center._addTransfer(transfer, toAccount: Registry.sharedInstance.iMessageAccount()!.uniqueID)
            
            if let map = center.value(forKey: "_guidToTransferMap") as? NSDictionary {
                map.setValue(transfer, forKey: guid)
                
                center.registerTransfer(withDaemon: guid)
                
                transfer.saveToDatabase(atPath: storedPath).map {
                    Attachment(transfer)
                }.cascade(to: promise)
            } else {
                promise.fail(Abort(.internalServerError))
            }
        }
        
        return promise.futureResult
    }
    
    let attachment = readAuthorizedAttachments.grouped(AttachmentMiddleware).grouped(":\(AttachmentResourceKey)")
    
    /**
     Get attachment
     */
    attachment.get { req -> Response in
        var cacheControl = HTTPHeaders.CacheControl()
        
        cacheControl.isPublic = true
        cacheControl.maxAge = 3600
        
        switch req.attachment.type.subType {
        case "heic":
            // transcode
            if let png = try Data(contentsOf: URL(fileURLWithPath: req.attachment.path)).pngRepresentation {
                let res = Response()
                res.headers.contentType = .png
                res.headers.cacheControl = cacheControl
                res.body = .init(data: png)
                return res
            }
            break
        default:
            break
        }
        
        let streamResponse = req.fileio.streamFile(at: req.attachment.path, mediaType: req.attachment.type)
        streamResponse.headers.cacheControl = cacheControl
        
        return streamResponse
    }
}
