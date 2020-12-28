//
//  HttpHeader.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket

struct BonjourRequest {
    let method:String
    let path:String
    let proto:String
    var headers:[String:String]
    var body:Data?
    
    init(path: String, method: String = "GET") {
        self.path = path
        self.method = method
        self.proto = "HTTP/1.1"
        self.headers = [:]
    }

    mutating func setBody(string: String, type: String="text/html") {
        body = Data(string.utf8)
        headers["Content-Length"] = String(body!.count)
        headers["Content-Type"] = type
        headers["charset"] = "UTF-8"
    }
    
    var headerData:Data {
        let headersSection = headers.map {
            "\($0):\($1)"
        }.joined(separator: "\r\n")
        return Data("\(method) \(path) \(proto)\r\n\(headersSection)\r\n\r\n".utf8)
    }

    init?(data:Data) {
        do {
            let (firstLine, headers, body) = try BonjourParser.parseHeader(data: data)
            let parts = firstLine.components(separatedBy: " ")
            guard parts.count == 3 else {
                throw BonjourParser.ParserError.invalidFirstLine
            }
            (method, path, proto) = (parts[0], parts[1], parts[2])
            self.body = body
            self.headers = headers
        } catch {
            print("### Error", error)
            return nil
        }
    }
}

extension BonjourRequest : CustomStringConvertible {
    var description: String {
        guard let body = body else {
            return "\(method) \(path) \(proto)"
        }
        return "\(method) \(path) \(proto), Body:\(body.count)"
    }
}
