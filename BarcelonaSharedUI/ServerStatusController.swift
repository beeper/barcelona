//
//  ServerStatusController.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftUI

public struct ServerStatusController: View {
    public init(runningModel: RunningModel, toggleIsRunning: @escaping () -> ()) {
        self.runningModel = runningModel
        self.toggleIsRunning = toggleIsRunning
    }
    
    @ObservedObject public var runningModel: RunningModel
    public var toggleIsRunning: () -> ()
    
    public var body: some View {
        Button(action: toggleIsRunning) {
            Text("\(running ? "Stop" : "Start") server")
        }.disabled(busy)
    }
    
    public var busy: Bool {
        runningModel.isBusy
    }
    
    public var running: Bool {
        runningModel.isRunning
    }
}
