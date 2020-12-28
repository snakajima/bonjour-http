//
//  BonjourResponce.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

struct BonjourReponce {
    let request:BonjourRequest
    var status = "200 OK"
    var body:Data? = nil
    var headers = [String:String]()
    
    init(request:BonjourRequest) {
        self.request = request
    }

    mutating func setBody(string: String, type: String="text/html") {
        body = Data(string.utf8)
        headers["Content-Length"] = String(body!.count)
        headers["Content-Type"] = type
        headers["charset"] = "UTF-8"
    }
    
    var headerData: Data {
        let headersSection = headers.map {
            "\($0):\($1)"
        }.joined(separator: "\r\n")
        return Data(
            ("\(request.method) \(status)\r\n"
            + "\(headersSection)\r\n\r\n").utf8)
    }
}
