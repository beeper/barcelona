//
//  BLJujitsuClient.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 7/5/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

class BLJujitsuClient {
    static let shared = BLJujitsuClient()
    
    func sendEvent(named name: String, payload: [String: Any]) {
        var request = URLRequest(url: URL(string: "http://localhost:9191/event")!)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "type": name,
            "event": payload
        ] as [String: Any], options: .prettyPrinted)
        
        URLSession.shared.dataTask(with: request).resume()
    }
}
