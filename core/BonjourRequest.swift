//
//  HttpHeader.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation
import CocoaAsyncSocket

public struct BonjourRequest {
    public enum Method: String {
        public typealias RawValue = String
        case Get = "GET"
        case Post = "POST"
        case Head = "HEAD"
        case Put = "PUT"
        case Delete = "DELETE"
        case Options = "OPTIONS"
        case Trace = "TRACE"
        case Patch = "PATCH"
    }
    public let method: Method
    public let path: String
    public let proto: String
    public var headers: [String:String]
    public var body: Data?
    var headerData: Data {
        let headersSection = headers.map {
            "\($0):\($1)"
        }.joined(separator: "\r\n")
        return Data("\(method.rawValue) \(path) \(proto)\r\n\(headersSection)\r\n\r\n".utf8)
    }
    var context: String {
        headers["X-Context"] ?? "__unspecified__"
    }

    public init(path: String, method: Method = .Get) {
        self.path = path
        self.method = method
        self.proto = "HTTP/1.1"
        self.headers = ["User-Agent":"bonjour-http", "Accept":"*/*"]
    }
    
    public mutating func setBody(data: Data, type: String) {
        body = data
        headers["Content-Length"] = String(data.count)
        headers["Content-Type"] = type
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
            BonjourLogError("BonjourRequest: setBodyJson failed")
        }
    }
    
    public var jsonBody:[String:Any]? {
        guard let body = body, headers["Content-Type"] == "application/json" else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: body, options: []) as? [String:Any]
    }

    init(result: BonjourParser.Result) {
        //let (firstLine, headers, body) = try BonjourParser.perse(data: data)
        let parts = result.firstLine.components(separatedBy: " ")
        if parts.count == 3, let method = Method(rawValue: parts[0]) {
            self.method = method
            (path, proto) = (parts[1], parts[2])
        } else {
            // Treat invalid header as the access to the root
            BonjourLogError("Invalid Fist Line \(result.firstLine)")
            (method, path, proto) = (.Get, "/", "HTTP/1.1")
        }
        self.body = result.body
        self.headers = result.headers
    }
}

extension BonjourRequest : CustomStringConvertible {
    public var description: String {
        guard let body = body else {
            return "\(method.rawValue) \(path) \(proto)"
        }
        return "\(method.rawValue) \(path) \(proto), Body:\(body.count)"
    }
}
