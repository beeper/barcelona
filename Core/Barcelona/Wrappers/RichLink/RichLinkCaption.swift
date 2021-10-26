//
//  RichLinkCaption.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation
import CoreGraphics

struct RichLinkCaption: Codable, Hashable {
    init(_ properties: LPCaptionBarPresentationProperties, attachments: [BarcelonaAttachment] = []) {
        if let aboveTop = properties.aboveTop, aboveTop.hasAnyContent {
            self.aboveTop = .init(aboveTop)
        }
        
        if let top = properties.top, top.hasAnyContent {
            self.top = .init(top)
        }
        
        if let bottom = properties.bottom, bottom.hasAnyContent {
            self.bottom = .init(bottom)
        }
        
        if let belowBottom = properties.belowBottom, belowBottom.hasAnyContent {
            self.belowBottom = .init(belowBottom)
        }
        
        if let leadingIcon = properties.leadingIcon {
            self.leadingIcon = RichLinkImage(leadingIcon, properties.leadingIconProperties, attachments: attachments)
        }
        
        if let trailingIcon = properties.trailingIcon {
            self.trailingIcon = RichLinkImage(trailingIcon, properties.trailingIconProperties, attachments: attachments)
        }
        
        if let additionalLeadingIcons = properties.additionalLeadingIcons, additionalLeadingIcons.count > 0 {
            CLDebug("LinkPresentation", "Found additional leading icons %@", additionalLeadingIcons as CVarArg)
        }
        
        if let additionalTrailingIcons = properties.additionalTrailingIcons, additionalTrailingIcons.count > 0 {
            CLDebug("LinkPresentation", "Found additional trailing icons %@", additionalTrailingIcons as CVarArg)
        }
        
        if !properties.leadingIconSize.height.isZero, !properties.leadingIconSize.width.isZero {
            leadingIconSize = properties.leadingIconSize
        }
        
        if !properties.trailingIconSize.height.isZero, !properties.trailingIconSize.width.isZero {
            trailingIconSize = properties.trailingIconSize
        }
    }
    
    var aboveTop: RichLinkCaptionRow?
    var top: RichLinkCaptionRow?
    var bottom: RichLinkCaptionRow?
    var belowBottom: RichLinkCaptionRow?
    var leadingIcon: RichLinkImage?
    var trailingIcon: RichLinkImage?
    var additionalTrailingIcons: [RichLinkImage]?
    var leadingAccessoryType: Int64?
    var trailingAccessoryType: Int64?
    var leadingIconSize: CGSize?
    var trailingIconSize: CGSize?
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
