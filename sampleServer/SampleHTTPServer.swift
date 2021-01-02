//
//  HTTPServer.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket

class SampleHTTPServer : NSObject, BonjourServiceDelegate {
    func service(_ service: BonjourService, onCall function: String, params: [String : Any], socket: GCDAsyncSocket, context: String) {
        print("onFuntion", function, params)
        switch(function) {
        case "foo":
            print("foo")
            let json = [
                "result": "How are you!"
            ]
            service.respond(to: socket, context: context, result: json)
        default:
            print("error")
        }
    }
    
    func service(_ service: BonjourService, onRequest request: BonjourRequest, socket: GCDAsyncSocket) {
        var res = BonjourResponce()
        switch(request.path) {
        case "/":
            res.setBody(string: "<html><body>Hello World!</body></html>")
        default:
            res.setBody(string: "<html><body>Page Not Found</body></html>")
            res.statusText = "404 Not Found"
        }
        service.send(responce: res, to: socket)
    }
}
