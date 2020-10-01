//
//  RunningModel.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftUI

public class RunningModel: ObservableObject {
    public init() {
        
    }
    
    @Published public var isRunning = false
    @Published public var isBusy = false
}
