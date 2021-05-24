//
//  TargetResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import NIO

public protocol TargetResolvable {
    var target_guid: String { get set }
}

public extension TargetResolvable {
    func resolveTarget() -> EventLoopFuture<Message?> {
        Message.lazyResolve(withIdentifier: target_guid)
    }
}
