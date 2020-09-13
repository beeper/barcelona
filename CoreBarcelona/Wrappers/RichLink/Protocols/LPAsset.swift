//
//  LPAsset.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

protocol LPAsset: NSObject {
    var fileURL: URL! { get set }
}

extension LPAudio: LPAsset {}
extension LPImage: LPAsset {}
extension LPVideo: LPAsset {}
