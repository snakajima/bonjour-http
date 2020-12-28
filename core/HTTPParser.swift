//
//  HttpHeader.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

struct HTTPParser {
    let method:String
    let path:String
    let proto:String
    let headers:[String:String]
    let body:Data?
    
    init?(data:Data) {
        let rows = data.split(separator: 0x0a)
        var headerLength = 0
        var counter = 0
        rows.forEach { (row) in
            if row.count == 1 && String(decoding:row, as:UTF8.self) == "\r" {
                headerLength = counter
            } else {
                counter += row.count + 1
            }
        }
        if headerLength == 0 {
            print("### no header")
            return nil
        }
        let headerData = data.subdata(in: 0..<headerLength)
        let bodyIndex = headerLength + 2
        if data.count == bodyIndex {
            body = nil
        } else {
            body = data.subdata(in: bodyIndex..<data.count)
        }
        
        let string = String(decoding:headerData, as:UTF8.self)
        var lines = string.components(separatedBy: "\n").map { $0.trimmingCharacters(in: CharacterSet(arrayLiteral: "\r"))}

        let parts = lines.removeFirst().components(separatedBy: " ")
        guard parts.count == 3 else {
            print("invalid first line", parts)
            return nil
        }
        (method, path, proto) = (parts[0], parts[1], parts[2])
        
        var headers = [String:String]()
        lines.forEach { line in
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces )}
            if parts.count == 2 {
                headers[parts.first!] = parts.last!
            }
        }
        self.headers = headers
    }
}

extension HTTPParser : CustomStringConvertible {
    var description: String {
        guard let body = body else {
            return "Method:\(method), Path:\(path), Protocol:\(proto)"
        }
        return "Method:\(method), Path:\(path), Protocol:\(proto), Body:\(body.count)"
    }
}
