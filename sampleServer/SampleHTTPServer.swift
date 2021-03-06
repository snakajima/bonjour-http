//
//  HTTPServer.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket
import AppKit

class SampleHTTPServer : NSObject, BonjourServiceDelegate, ObservableObject {
    @Published public var clients = [GCDAsyncSocket]()
    @Published public var isRunning = false
    @Published public var image: CGImage? = nil
    
    func serviceClientsDidChange(_ service: BonjourService) {
        clients = service.clients
    }

    func serviceRunningStateDidChange(_ service: BonjourService) {
        isRunning = service.isRunning
    }    

    func service(_ service: BonjourService, onCall: String, params: [String : Any], socket: GCDAsyncSocket, context: String) {
        switch(onCall) {
        case "foo":
            let delay = params["delay"] as? Double ?? 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                service.respond(to: socket, context: context, result: ["result": "How are you? \(delay)"])
            }
        default:
            service.respond(to: socket, context: context, result: ["error": "invalid function name"],
                            statusText: "404 Not found")
        }
    }
    
    func service(_ service: BonjourService, onRequest req: BonjourRequest, socket: GCDAsyncSocket, context: String) {
        var res = BonjourResponse(context: context)
        switch(req.path) {
        case "/":
            res.setBody(string: "<html><body>Hello World!</body></html>")
        case "/image" where req.method == .Post:
            if let body = req.body {
                image = NSImage(data: body)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
            }
        default:
            res.setBody(string: "<html><body>Page Not Found</body></html>")
            res.statusText = "404 Not Found"
        }
        service.send(responce: res, to: socket)
    }
}
