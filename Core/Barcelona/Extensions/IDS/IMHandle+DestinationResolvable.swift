//
//  IMHandle+DestinationResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/10/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMFoundation
import IMCore
import IDS

public extension IMHandle {
    var idsStatus: IDSState {
        (try? BLResolveIDStatusForIDs([id], onService: service.id))?.first?.value ?? .unknown
    }
    
    func lazyIDSStatus() -> Promise<IDSState> {
        Promise { resolve, reject in
            do {
                try BLResolveIDStatusForIDs([self.id]) {
                    resolve($0.first?.value ?? .unknown)
                }
            } catch {
                reject(error)
            }
        }
    }
}
