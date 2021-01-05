//
//  HttpHeader.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket

public struct BonjourRequest {
    public let method: String
    public let path: String
    public let proto: String
    public var headers: [String:String]
    public var body: Data?
    var headerData: Data {
        let headersSection = headers.map {
            "\($0):\($1)"
        }.joined(separator: "\r\n")
        return Data("\(method) \(path) \(proto)\r\n\(headersSection)\r\n\r\n".utf8)
    }

    public init(path: String, method: String = "GET") {
        self.path = path
        self.method = method
        self.proto = "HTTP/1.1"
        self.headers = ["User-Agent":"bonjour-http", "Accept":"*/*"]
    }

    public mutating func setBody(string: String, type: String="text/html") {
        body = Data(string.utf8)
        headers["Content-Length"] = String(body!.count)
        headers["Content-Type"] = type
        headers["charset"] = "UTF-8"
    }

    public mutating func setBody(json: [String:Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []) {
            body = data
            headers["Content-Length"] = String(body!.count)
            headers["Content-Type"] = "application/json"
        } else {
            print("BonjourRequest: setBodyJson failed")
        }
    }
    
    public var jsonBody:[String:Any]? {
        guard let body = body, headers["Content-Type"] == "application/json" else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: body, options: []) as? [String:Any]
    }

    init(result: BonjourParser.Result) {
        //let (firstLine, headers, body) = try BonjourParser.parseHeader(data: data)
        let parts = result.firstLine.components(separatedBy: " ")
        if parts.count == 3 {
            (method, path, proto) = (parts[0], parts[1], parts[2])
        } else {
            // Treat invalid header as the access to the root
            print("### ERROR Invalid Fist Line", result.firstLine)
            (method, path, proto) = ("GET", "/", "HTTP/1.1")
        }
        self.body = result.body
        self.headers = result.headers
    }
}

extension BonjourRequest : CustomStringConvertible {
    public var description: String {
        guard let body = body else {
            return "\(method) \(path) \(proto)"
        }
        return "\(method) \(path) \(proto), Body:\(body.count)"
    }
}
