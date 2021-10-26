////  main.swift
//  imserver
//
//  Created by Eric Rabil on 10/6/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import http
import Barcelona
import SwiftCLI
import Yammit

struct IMServerConfiguration: Codable, Configuration {
    static let path = ("~/.imserver.yml" as NSString).expandingTildeInPath
    static let shared = IMServerConfiguration.load()
    
    // Mapping of webhook token <-> chatID
    var webhooks = [String: String]()
}

struct IMWebhookMessage: Codable {
    let text: String
}

class IMWebhookController {
    static let shared = IMWebhookController()
    
    func handle(_ request: IncomingMessage, _ response: ServerResponse) {
        var dead = false
        request.onReadable {
            guard !dead else { return }
            dead = true
            
            let data = Data(request.read() ?? [])
            guard let token = request.headers["authorization"] as? String else {
                return response.status(400).json(["message": "missing token"])
            }
            
            guard let chatID = IMServerConfiguration.shared.webhooks[token] else {
                return response.status(400).json(["message": "bad token"])
            }
            
            guard let message = try? JSONDecoder().decode(IMWebhookMessage.self, from: data) else {
                return response.status(400).json(["message": "bad body"])
            }
            
            guard let chat = Chat.resolve(withIdentifier: chatID) else {
                return response.status(404).json(["message": "unknown chat"])
            }
            
            do {
                try response.status(200).json(chat.send(message: .init(parts: [.init(type: .text, details: message.text)])))
            } catch {
                response.status(500).json(["message": "couldn't send message"])
            }
        }
    }
}

protocol Codablish {}
extension String: Codablish{}
extension NSNumber: Codablish{}
extension Int: Codablish{}
extension NSString: Codablish{}

extension Dictionary: Codablish where Key: Codablish, Value: Codablish {}

var deaths = Set<ObjectIdentifier>()
var pending = Set<ObjectIdentifier>()

extension ServerResponse {
    func status(_ code: Int) -> Self {
        if deaths.contains(id) {
            return self
        }
        
        writeHead(code)
        return self
    }
    
    func json<P: Encodable>(_ body: P) {
        pending.remove(id)
        if let _ = deaths.remove(id) {
            return
        }
        
        end([UInt8](try! JSONEncoder().encode(body)))
    }
    
    func json(_ value: Codablish) {
        pending.remove(id)
        if let _ = deaths.remove(id) {
            return
        }
        
        end([UInt8](try! JSONSerialization.data(withJSONObject: value, options: [])))
    }
    
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

class IMServer: Command {
    static let shared = IMServer()
    
    let name = "server"
    
    @Key("-p", "--port")
    var port: Int?
    
    func execute() throws {
        http.createServer() { req, res in
            pending.insert(res.id)
            
            res.onClose {
                guard pending.contains(res.id) else {
                    return
                }
                
                deaths.insert(res.id)
            }
            
            guard let components = URLComponents(string: req.url) else {
                return res.status(400)
                    .json([
                        "message": ""
                    ])
            }
            
            switch components.path {
            case "/api/v1/webhook":
                guard req.method.lowercased() == "post" else {
                    fallthrough
                }
                
                IMWebhookController.shared.handle(req, res)
            default:
                res.status(404)
                    .json(["message":"bad route"])
            }
        }.listen(port ?? 9999)
    }
}

BarcelonaManager.shared.bootstrap().then { success in
    guard success else {
        fatalError("Failed to bootstrap")
    }
    
    CLI(singleCommand: IMServer.shared).go()
    
    print("yassss")
}

RunLoop.main.run()
