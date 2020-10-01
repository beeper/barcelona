//
//  main.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BarcelonaVapor
import BarcelonaFoundation
import os.log
import NIO

#if os(iOS)
ERTellJetsamToFuckOff()
#endif

if ERRunningOutOfAgent() || ProcessInfo.processInfo.environment["ERAgentShouldRunServerOnBoot"] != nil {
    ERBarcelonaAPIService.sharedInstance.start { error in
        if let error = error {
            os_log("Failed to start API service with error %@, exiting", error.localizedDescription)
            exit(-1)
        }
    }
}

if ProcessInfo.processInfo.environment["ERRunningOutOfAgent"] == nil {
    ERBarcelonaAPIService.sharedInstance.runXPC()
}

RunLoop.main.run()
