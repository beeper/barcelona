//
//  ContentView.swift
//  imessage-rest-mac-controller
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import SwiftUI
import BarcelonaFoundation
import BarcelonaSharedUI
import os.log
import Combine

struct ServerStatusView: View {
    @Binding var isRunning: Bool
    
    var body: some View {
        Circle()
            .fill(isRunning ? Color.green : Color.red)
    }
}

struct OriginEntry: Identifiable, Hashable {
    static func == (lhs: OriginEntry, rhs: OriginEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    var id = UUID()
    @State var origin: String
    
    var hashValue: Int {
        id.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
}

class ObservableArray<T>: ObservableObject {
    @Published var array: [T] = []
    var cancellables = [AnyCancellable]()

    init(array: [T]) {
        self.array = array
    }
    
    subscript(_ index: Int) -> T {
        get {
            array[index]
        }
        set {
            array[index] = newValue
        }
    }
    
    var count: Int {
        array.count
    }
    
    func append(_ newElement: T) {
        array.append(newElement)
        print(array)
    }
    
    func remove(at index: Int) {
        array.remove(at: index)
    }
}

class AllowedOriginsModel: ObservableObject {
    @Published var origins = [String]()
    
    subscript(_ index: Int) -> String {
        get {
            origins[index]
        }
        set {
            origins[index] = newValue
        }
    }
    
    var count: Int {
        origins.count
    }
    
    func append(_ newElement: String) {
        origins.append(newElement)
    }
    
    func remove(at index: Int) {
        origins.remove(at: index)
    }
}

func promptForSingleFile(withAllowedTypes allowedTypes: [String]?, callback: @escaping (String?) -> ()) {
    let panel = NSOpenPanel()
    
    panel.allowedFileTypes = allowedTypes
    
    panel.begin { response in
        callback(panel.url?.path)
    }
}

struct ContentView: View {
    @ObservedObject var runningModel: RunningModel = RunningModel()
    @ObservedObject var configuration: ConfigurationModel = ConfigurationModel()
    @ObservedObject var allowedOriginModel: ObservableArray<String> = ObservableArray<String>(array: [String]())
    @State private var selectKeeper = Set<String>()
    
    var body: some View {
        VStack(spacing: .none) {
            ServerStatus(runningModel: runningModel).frame(alignment: .topLeading).padding(.top, 10).padding(.bottom, 5)
            
            Spacer()
            
            VStack {
                VStack {
                    HStack {
                        Text("Port")
                        TextField("Port Number", value: $configuration.portNumber, formatter: NumberFormatter()).frame(width: 50)
                    }
                    HStack {
                        Text("Hostname")
                        TextField("Hostname", text: $configuration.hostname).frame(width: 125)
                    }
                    HStack {
                        Text("Max Body Size")
                        TextField("Max Body Size", text: $configuration.maxBodySize).frame(width: 50)
                    }
                    Divider()
                    VStack {
                        Text("SSL")
                        HStack {
                            Text("Public Key").frame(minWidth: 75)
                            Button(action: pickPublicKey) {
                                Text("Change")
                            }
                            Button(action: deletePublicKey) {
                                Text("Delete")
                            }.disabled(configuration.publicKeyPath == nil)
                            if shouldShowPublicKeyPath() {
                                Text("Path: ").foregroundColor(.secondary)
                                Text(configuration.publicKeyPath!)
                            }
                            Spacer()
                        }
                        HStack {
                            Text("Private Key").frame(minWidth: 75)
                            Button(action: pickPrivateKey) {
                                Text("Change")
                            }
                            Button(action: deletePrivateKey) {
                                Text("Delete")
                            }.disabled(configuration.privateKeyPath == nil)
                            if shouldShowPrivateKeyPath() {
                                Text("Path: ").foregroundColor(.secondary)
                                Text(configuration.privateKeyPath!)
                            }
                            Spacer()
                        }
                    }
                    Divider()
                    VStack {
                        Text("Allowed Origins")
                        OriginNSTable(originsModel: allowedOriginModel)
                    }
                    Spacer()
                    Button(action: saveConfiguration) {
                        Text("Save Configuration")
                    }
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .padding(20)
                .background(Color.init(Color.RGBColorSpace.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05))
                .cornerRadius(5)
            }.frame(minWidth: 0, maxWidth: .infinity).padding(.horizontal, 20)

            Spacer()
            
            ServerStatusController(runningModel: runningModel, toggleIsRunning: toggleIsRunning).disabled(busy).padding(.top, 5).padding(.bottom, 10)
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func shouldShowPrivateKeyPath() -> Bool {
        configuration.privateKeyPath != nil
    }
    
    func shouldShowPublicKeyPath() -> Bool {
        configuration.publicKeyPath != nil
    }
    
    func loadConfiguration(_ configuration: ERHTTPServerConfiguration) {
        self.configuration.portNumber = configuration.port
        self.configuration.hostname = configuration.hostname
        self.configuration.maxBodySize = configuration.maxBodySize
        self.configuration.publicKeyPath = configuration.publicKeyPath
        self.configuration.privateKeyPath = configuration.privateKeyPath
        self.allowedOriginModel.array = configuration.allowedCorsOrigin ?? []
    }
    
    func pickPublicKey() {
        promptForPEM { path in
            ERHTTPServerConfiguration.storedPublicKeyPath = path
            self.configuration.publicKeyPath = path
        }
    }
    
    func pickPrivateKey() {
        promptForPEM { path in
            ERHTTPServerConfiguration.storedPrivateKeyPath = path
            self.configuration.privateKeyPath = path
        }
    }
    
    private func promptForPEM(callback: @escaping (String?) -> ()) {
        promptForSingleFile(withAllowedTypes: ["pem"], callback: callback)
    }
    
    func deletePublicKey() {
        ERHTTPServerConfiguration.storedPublicKeyPath = nil
        self.configuration.publicKeyPath = nil
    }
    
    func deletePrivateKey() {
        ERHTTPServerConfiguration.storedPrivateKeyPath = nil
        self.configuration.privateKeyPath = nil
    }
    
    var compiledConfiguration: ERHTTPServerConfiguration {
        ERHTTPServerConfiguration(port: configuration.portNumber, hostname: configuration.hostname, maxBodySize: configuration.maxBodySize, allowedCorsOrigin: allowedOriginModel.array.count == 0 ? nil : allowedOriginModel.array, publicKeyPath: configuration.publicKeyPath, privateKeyPath: configuration.privateKeyPath)
    }
    
    func saveConfiguration() {
        compiledConfiguration.storeToDefaults()
    }
    
    func applyRunning(_ running: Bool) {
        runningModel.isRunning = running
        runningModel.isBusy = false
    }
    
    func toggleIsRunning() {
        if busy {
            return
        }
        
        runningModel.isBusy = true
        
        if running {
            RemoteController.sharedInstance.stop()
        } else {
            RemoteController.sharedInstance.start()
        }
    }
    
    var busy: Bool {
        runningModel.isBusy
    }
    
    var running: Bool {
        runningModel.isRunning
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
