//
//  BonjourResponce.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

struct BonjourResponce {
    let proto: String
    var status = "200"
    var statusText = "OK"
    var body: Data? = nil
    var headers = [String:String]()
    
    init() {
        proto = "HTTP/1.1"
    }

    init?(data: Data) {
        do {
            let (firstLine, headers, body) = try BonjourParser.parseHeader(data: data)
            let parts = firstLine.components(separatedBy: " ")
            guard parts.count == 3 else {
                throw BonjourParser.ParserError.invalidFirstLine
            }
            (proto, status, statusText) = (parts[0], parts[1], parts[2])
            self.body = body
            self.headers = headers
        } catch {
            return nil
        }
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
            ("\(proto) \(status) \(statusText)\r\n"
            + "\(headersSection)\r\n\r\n").utf8)
    }
}

extension BonjourResponce : CustomStringConvertible {
    var description: String {
        guard let body = body else {
            return "\(proto) \(status) \(statusText)"
        }
        return "\(proto) \(status) \(statusText), Body:\(body.count)"
    }
}
