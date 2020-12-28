//
//  HTTPServer.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

class HTTPServer : NSObject {
}

extension HTTPServer : BonjourServiceDelegate {
    func on(reqeust: HTTPRequest, service: BonjourService) {
    }
}
