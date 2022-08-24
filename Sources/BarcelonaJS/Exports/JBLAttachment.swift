//
//  JBLAttachment.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona

@objc
public protocol JBLAttachmentJSExports: JSExport {
    var id: String { get set }
    var filename: String? { get set }
    var path: String? { get set }
    var mime: String? { get set }
}

@objc
public class JBLAttachment: NSObject, JBLAttachmentJSExports {
    public dynamic var id: String
    public dynamic var filename: String?
    public dynamic var path: String?
    public dynamic var mime: String?
    
    public init(attachment: Attachment) {
        id = attachment.id
        filename = attachment.filename
        path = attachment.path
        mime = attachment.mime
    }
}
