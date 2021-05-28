//
//  main.swift
//  barcelona-mautrix
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaMautrixIPC

BLCreatePayloadReader { payload in
    
}

RunLoop.current.add(Timer(timeInterval: 1, repeats: true) { _ in
    BLInfo("test")
}, forMode: .default)

RunLoop.current.run()
