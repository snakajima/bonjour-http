//
//  HTTPServer.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket

class SampleHTTPServer : NSObject, BonjourServiceDelegate {
    func on(reqeust: BonjourRequest, service: BonjourService, socket: GCDAsyncSocket) {
        var res = BonjourResponce()
        switch(reqeust.path) {
        case "/":
            res.setBody(string: "<html><body>Hello World!</body></html>")
        default:
            res.setBody(string: "<html><body>Page Not Found</body></html>")
            res.status = "404"
            res.statusText = "Not Found"
        }
        service.send(responce: res, to: socket)
    }
}
