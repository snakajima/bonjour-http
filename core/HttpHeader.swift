//
//  HttpHeader.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import Foundation

struct HTTPHeader {
    let method:String
    let path:String
    let proto:String
    let headers:[String:String]
    
    init?(string:String) {
        var lines = string.components(separatedBy: "\n").map { $0.trimmingCharacters(in: CharacterSet(arrayLiteral: "\r"))}

        let parts = lines.removeFirst().components(separatedBy: " ")
        guard parts.count == 3 else {
            print("invalid first line", parts)
            return nil
        }
        (method, path, proto) = (parts[0], parts[1], parts[2])
        
        let lastLine = lines.removeLast()
        guard lastLine == "" else {
            print("invalid last line")
            return nil
        }
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

extension HTTPHeader : CustomStringConvertible {
    var description: String {
        "Method:\(method), Path:\(path), Protocol:\(proto)"
    }
}
