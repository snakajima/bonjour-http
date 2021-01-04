//
//  BonjourResponce.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

public struct BonjourResponse {
    public let proto: String
    public var statusText = "200 OK"
    public var status:Int { Int(statusText.components(separatedBy: " ").first!) ?? 0 }
    public var isSuccess:Bool { status >= 200 && status < 300 }
    public var body: Data? = nil
    public var headers = [String:String]()
    
    public init() {
        proto = "HTTP/1.1"
    }

    init?(data: Data) {
        do {
            let (firstLine, headers, body) = try BonjourParser.parseHeader(data: data)
            var parts = firstLine.components(separatedBy: " ")
            proto = parts.removeFirst()
            statusText = parts.joined(separator: " ")
            self.body = body
            self.headers = headers
        } catch {
            return nil
        }
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

    public var headerData: Data {
        let headersSection = headers.map {
            "\($0):\($1)"
        }.joined(separator: "\r\n")
        return Data(
            ("\(proto) \(statusText)\r\n"
            + "\(headersSection)\r\n\r\n").utf8)
    }
}

extension BonjourResponse : CustomStringConvertible {
    public var description: String {
        guard let body = body else {
            return "\(proto) \(statusText)"
        }
        return "\(proto) \(statusText), Body:\(body.count)"
    }
}
