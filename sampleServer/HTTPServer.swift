//
//  HTTPServer.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket

class HTTPServer : NSObject {
}

extension HTTPServer : BonjourServiceDelegate {
    func on(reqeust: HTTPRequest, service: BonjourService, socket: GCDAsyncSocket) {
        service.send(to: socket, string: "Merry X'mas")
    }
}
