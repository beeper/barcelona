//
//  DocumentPicker.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import UIKit

class DocumentPickerViewController: UIDocumentPickerViewController {
    private let onDismiss: () -> Void
    private let onPick: (URL) -> ()
    
    static func pickFile(supportedTypes: [CFString], callback: @escaping (String?) -> ()) {
        let picker = DocumentPickerViewController(supportedTypes: supportedTypes, onPick: { url in
            callback(url.path)
        }, onDismiss: {
            callback(nil)
        })
        
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }

    init(supportedTypes: [CFString], onPick: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onPick = onPick

        super.init(documentTypes: supportedTypes as [String], in: .open)

        allowsMultipleSelection = false
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick(urls.first!)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onDismiss()
    }
}
