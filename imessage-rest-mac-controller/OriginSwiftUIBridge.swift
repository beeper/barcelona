//
//  OriginSwiftUIBridge.swift
//  imessage-rest-mac-controller
//
//  Created by Eric Rabil on 9/25/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI

class OriginTableView: NSTableView {
    
}

class OriginTableState: ObservableObject {
    @Published var origins: [String] = []
}

class OriginNSTableController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var scrollView: NSScrollView!
    var tableView: OriginTableView!
    var controls: NSSegmentedControl!
    var baseView: NSStackView!
    var table: OriginNSTable!
    
    var origins: ObservableArray<String> {
        table.originsModel
    }
    
    var removeAtIndex: (Int) -> () = { _ in }
    var setAtIndex: (Int, String?) -> () = { _, _ in }
    var addToEnd: (String) -> () = { _ in }
    
    override func loadView() {
        baseView = .init()
        
        baseView.orientation = .vertical
        
        scrollView = .init()
        controls = .init()
        tableView = .init()
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "Origin"))
        
        tableView.headerView = nil
        tableView.addTableColumn(column)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        
        baseView!.addView(scrollView, in: .top)
        
        controls.segmentStyle = .smallSquare
        controls.trackingMode = .momentary
        controls.segmentCount = 2
        controls.setImage(.init(imageLiteralResourceName: "NSAddTemplate"), forSegment: 0)
        controls.setImage(.init(imageLiteralResourceName: "NSRemoveTemplate"), forSegment: 1)
        controls.setWidth(20, forSegment: 0)
        controls.setWidth(20, forSegment: 1)
        controls.target = self
        controls.action = #selector(segmentSelected(_:))
        
        baseView!.addView(controls, in: .bottom)
        
        controls.leftAnchor.constraint(equalTo: baseView.leftAnchor).isActive = true
//        controls.rightAnchor.constraint(equalTo: baseView.rightAnchor).isActive = true
        
        self.view = baseView
    }
    
    @objc func segmentSelected(_ sender: Any) {
        switch controls.selectedSegment {
        case 0:
            addToEnd("")
        case 1:
            let selectedRow = tableView.selectedRow
            if selectedRow >= 0 {
                removeAtIndex(selectedRow)
            }
        default:
            return
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        origins.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard origins.count > row else {
            return nil
        }
        
        return origins[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let origin = object as? String
        
        setAtIndex(row, origin)
    }
    
    func refresh() {
        self.tableView?.reloadData()
        self.tableView?.noteNumberOfRowsChanged()
        print(self.origins)
    }
}

struct OriginNSTable: NSViewControllerRepresentable {
//    @Binding var origins: [String]
    @ObservedObject var originsModel: ObservableArray<String>

    typealias NSViewControllerType = OriginNSTableController

    func makeNSViewController(
        context: NSViewControllerRepresentableContext<OriginNSTable>
    ) -> OriginNSTableController {
        let controller = OriginNSTableController()
        controller.table = self
        
        controller.addToEnd = {
            self.originsModel.append($0)
        }
        
        controller.removeAtIndex = {
            self.originsModel.remove(at: $0)
        }
        
        controller.setAtIndex = {
            if let newValue = $1 {
                self.originsModel[$0] = newValue
            } else {
                self.originsModel.remove(at: $0)
            }
        }
        
        return controller
    }

    func updateNSViewController(
        _ nsViewController: OriginNSTableController,
        context: NSViewControllerRepresentableContext<OriginNSTable>
    ) {
        nsViewController.refresh()
    }
}
