//
//  URL+SS.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

internal extension CFURLEnumerator {
    func next() throws -> CFURL? {
        var error: Unmanaged<CFError>?, url: Unmanaged<CFURL>?
        
        switch CFURLEnumeratorGetNextURL(self, &url, &error) {
        case .success:
            return url?.takeUnretainedValue()
        case .error:
            if let error = error?.takeRetainedValue() {
                throw error
            }
            fallthrough
        default:
            return nil
        }
    }
}

public extension URL {
    func parseDirectoryToSwiftNodes() throws -> [SwiftNode] {
        guard let enumerator = CFURLEnumeratorCreateForDirectoryURL(kCFAllocatorDefault, self as CFURL, .descendRecursively, [] as CFArray) else {
            return []
        }
        
        var nodes = [SwiftNode]()
        
        while let url = try enumerator.next() as URL? {
            guard !url.hasDirectoryPath else {
                continue
            }
            
            let tree = try SyntaxParser.parse(url)
            
            nodes.insert(contentsOf: SwiftNode.eat(parser: tree), at: 0)
        }
        
        return nodes
    }
}
