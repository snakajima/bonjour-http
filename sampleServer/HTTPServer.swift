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
    func on(reqeust: BonjourRequest, service: BonjourService, socket: GCDAsyncSocket) {
        let response = BonjourRequest(path: "/")
        service.send(to: socket, string: "Merry X'mas")
    }
}
