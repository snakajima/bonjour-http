//
//  BonjourResponce.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

struct BonjourReponce {
    let proto:String
    var status = "200"
    var statusText = "OK"
    var body:Data? = nil
    var headers = [String:String]()
    
    init(request:BonjourRequest) {
        proto = request.proto
    }

    init?(data:Data) {
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
            print("### Error", error)
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

extension BonjourReponce : CustomStringConvertible {
    var description: String {
        guard let body = body else {
            return "\(proto) \(status) \(statusText)"
        }
        return "\(proto) \(status) \(statusText), Body:\(body.count)"
    }
}
