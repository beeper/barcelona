//
//  CNContact+Identifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import IMCore

extension CNContact: Identifiable {
    public var id: String {
        identifier
    }
}

public extension IMHandle {
    private static let lazy_businessPhotoData: (IMHandle) -> Data? = CBSelectLinkingPath([
        [.preMonterey]: { handle in
            handle.mapItemImageData
        },
        [.monterey]: { handle in
            handle.brandSquareLogoImageData()
        }
    ]) ?? { _ in nil }
    
    var businessPhotoData: Data? {
        IMHandle.lazy_businessPhotoData(self)
    }
    
    var photoData: Data? {
        if isBusiness() {
            return businessPhotoData
        } else {
            return pictureData
        }
    }
    
    func thumbnailImage(size targetingSize: Int?) -> ThumbnailImageData? {
        photoData?.resized(toSize: targetingSize)
    }
}
