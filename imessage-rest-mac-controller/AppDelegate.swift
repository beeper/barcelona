//
//  AppDelegate.swift
//  imessage-rest-mac-controller
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Cocoa
import SwiftUI
import BarcelonaFoundation
import os.log

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()
        
        RemoteController.sharedInstance.connect()
        
        NotificationCenter.default.addObserver(forName: .runningStateChanged, model: BarcelonaIsRunningMessage.self) {
            contentView.applyRunning($0.isRunning)
        }
        
        contentView.loadConfiguration(ERHTTPServerConfiguration.storedConfiguration)

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

