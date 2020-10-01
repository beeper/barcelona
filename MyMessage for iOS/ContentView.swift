//
//  ContentView.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/27/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import SwiftUI
import BarcelonaFoundation
import BarcelonaSharedUI
import Combine
import CoreServices
import os.log

struct OriginView: View {
    @State private var origins: [String] = ERHTTPServerConfiguration.storedAllowedCorsOrigin ?? []
    @State private var editMode = EditMode.inactive
    
    var body: some View {
        List {
            ForEach(origins.indices, id: \.self) { item in
                TextField("Origin", text: Binding(get: {
                    self.origins[item]
                }, set: {
                    self.origins[item] = $0
                    }), onCommit: self.store).keyboardType(.URL).autocapitalization(.none).disableAutocorrection(true)
            }.onDelete(perform: onDelete)
            
            if origins.count == 0 {
                Text("Add an origin to enable CORS").foregroundColor(.secondary)
            }
        }
        .navigationBarTitle("CORS Origins")
        .navigationBarItems(trailing: addButton)
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus") })
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func onDelete(offsets: IndexSet) {
        offsets.forEach {
            origins.remove(at: $0)
        }
        store()
    }
    
    private func onAdd() {
        origins.append("k")
        store()
    }
    
    private func store() {
        if origins.count == 0 {
            ERHTTPServerConfiguration.storedAllowedCorsOrigin = nil
        } else {
            ERHTTPServerConfiguration.storedAllowedCorsOrigin = origins
        }
    }
}

struct SSLView: View {
    @State var configuration: ConfigurationModel = ConfigurationModel().reload()
    
    var body: some View {
        configuration = configuration.reload()
        
        return Form {
            Section(header: Text("Public Key")) {
                if shouldShowPublicKeyPath() {
                    Text(configuration.publicKeyPath!)
                }
                Button(action: pickPublicKey, label: {
                    Text("\(shouldShowPublicKeyPath() ? "Change" : "Select") Public Key")
                })
                if shouldShowPublicKeyPath() {
                    Button(action: deletePublicKey, label: {
                        Text("Delete Public Key")
                    }).foregroundColor(.red)
                }
            }
            
            Section(header: Text("Private Key")) {
                if shouldShowPrivateKeyPath() {
                    Text(configuration.privateKeyPath!)
                }
                Button(action: pickPrivateKey, label: {
                    Text("\(shouldShowPrivateKeyPath() ? "Change" : "Select") Private Key")
                })
                if shouldShowPrivateKeyPath() {
                    Button(action: deletePrivateKey, label: {
                        Text("Delete Private Key")
                    }).foregroundColor(.red)
                }
            }
        }.navigationBarTitle("SSL")
    }
    
    func pickPublicKey() {
        getPEM { path in
            guard let path = path else {
                return
            }
            
            ERHTTPServerConfiguration.storedPublicKeyPath = path
            self.configuration = ConfigurationModel().reload()
        }
    }
    
    func deletePublicKey() {
        ERHTTPServerConfiguration.storedPublicKeyPath = nil
        self.configuration = ConfigurationModel().reload()
    }
    
    func shouldShowPublicKeyPath() -> Bool {
        configuration.publicKeyPath != nil
    }
    
    func pickPrivateKey() {
        getPEM { path in
            guard let path = path else {
                return
            }
            
            ERHTTPServerConfiguration.storedPrivateKeyPath = path
            self.configuration = ConfigurationModel().reload()
        }
    }
    
    private func getPEM(callback: @escaping (String?) -> ()) {
        DocumentPickerViewController.pickFile(supportedTypes: [kUTTypeX509Certificate], callback: callback)
    }
    
    func deletePrivateKey() {
        ERHTTPServerConfiguration.storedPrivateKeyPath = nil
        self.configuration = ConfigurationModel().reload()
    }
    
    func shouldShowPrivateKeyPath() -> Bool {
        configuration.privateKeyPath != nil
    }
}

struct ContentView: View {
    @State private var selection = 0
    @State private var configuration = ConfigurationModel().reload()
    @ObservedObject private var runningModel = RunningModel()
    @State private var allowedOrigins: ObservableArray<String> = ObservableArray<String>(array: [String]())
 
    var body: some View {
        TabView {
            VStack {
                ServerStatus(runningModel: runningModel)
                ServerStatusController(runningModel: runningModel, toggleIsRunning: toggleIsRunning)
            }.tabItem {
                Image(systemName: "cloud")
                Text("Server")
            }
            
            NavigationView {
                Form {
                    Section(header: Text("Port Number")) {
                        TextField("Port Number", value: $configuration.portNumber, formatter: NumberFormatter(), onCommit: {
                            ERHTTPServerConfiguration.storedPort = self.configuration.portNumber
                        })
                    }
                    
                    Section(header: Text("Hostname")) {
                        TextField("Hostname", text: $configuration.hostname, onCommit: {
                            ERHTTPServerConfiguration.storedHostname = self.configuration.hostname
                        })
                    }
                    
                    Section(header: Text("Max Body Size")) {
                        TextField("Max Body Size", text: $configuration.maxBodySize, onCommit: {
                            ERHTTPServerConfiguration.storedMaxBodySize = self.configuration.maxBodySize
                        })
                    }
                    
                    NavigationLink(destination: SSLView()) {
                        Text("SSL")
                        Spacer()
                    }
                    
                    NavigationLink(destination: OriginView()) {
                        Text("CORS Origins")
                        Spacer()
                    }
                }
                .navigationBarTitle("Settings")
            }.tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
    
    func applyRunning(_ running: Bool) {
        os_log("Bitch its time to apply! are we fucking running?! %d", running)
        self.runningModel.isRunning = running
        self.runningModel.isBusy = false
    }
    
    func toggleIsRunning() {
        if busy {
            return
        }
        
        runningModel.isBusy = true
        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.runningModel.isRunning = !self.runningModel.isRunning
            self.runningModel.isBusy = false
        }
        #else
        if running {
            RemoteController.sharedInstance.stop()
        } else {
            RemoteController.sharedInstance.start()
        }
        #endif
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
