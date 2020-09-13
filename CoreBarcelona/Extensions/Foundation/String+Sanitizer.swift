//
//  String+Sanitizer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension String {
    func sanitized() -> String {
        // see for ressoning on charachrer sets https://superuser.com/a/358861
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        
        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
    }
    
    mutating func sanitize() -> Void {
        self = self.sanitized()
    }
    
    func whitespaceCondenced() -> String {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    mutating func condenceWhitespace() -> Void {
        self = self.whitespaceCondenced()
    }
}
