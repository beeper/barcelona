//
//  ServerStatus.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftUI

public struct ServerStatus: View {
    public init(runningModel: RunningModel) {
        self.runningModel = runningModel
    }
    
    @ObservedObject public var runningModel: RunningModel
    
    public var body: some View {
        HStack(spacing: .none) {
            Circle().fill(statusColor).fixedSize()
            Text("Server is \(serverState)")
        }
    }
    
    public var running: Bool {
        runningModel.isRunning
    }
    
    public var busy: Bool {
        runningModel.isBusy
    }
    
    public var statusColor: Color {
        return busy ? .yellow : running ? .green : .red
    }
    
    public var serverState: String {
        if running {
            return busy ? "stopping" : "running"
        } else {
            return busy ? "starting" : "stopped"
        }
    }
}
