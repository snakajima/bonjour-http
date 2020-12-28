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
        var res = BonjourResponce(request: reqeust)
        res.setBody(string: "<html><body>Hello World!</body></html>")
        service.send(responce: res, to: socket)
    }
}
