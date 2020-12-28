//
//  BonjourParser.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/28/20.
//

import Foundation

class BonjourParser {
    enum ParserError : Error {
        case invalidFirstLine
        case incompleteHeader
        case incompleteBody
        case missingContentLength
    }
    
    private static func extractHeader(data:Data) throws -> (Data, Data?) {
        // LATER: Optimize it for a very large body
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
            throw ParserError.incompleteHeader
        }
        let headerData = data.subdata(in: 0..<headerLength)
        let bodyIndex = headerLength + 2
        let body:Data?
        if data.count == bodyIndex {
            body = nil
        } else {
            body = data.subdata(in: bodyIndex..<data.count)
        }
        return (headerData, body)
    }
    
    private static func extractHeaders(headerData:Data) -> (String, [String:String]) {
        let string = String(decoding:headerData, as:UTF8.self)
        var lines = string.components(separatedBy: "\n").map { $0.trimmingCharacters(in: CharacterSet(arrayLiteral: "\r"))}
        let firstLine = lines.removeFirst()
        var headers = [String:String]()
        
        lines.forEach { line in
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces )}
            if parts.count == 2 {
                headers[parts.first!] = parts.last!
            }
        }
        return (firstLine, headers)
    }
    
    static func parseHeader(data: Data) throws -> (String, [String:String], Data?) {
        let (headerData, body) = try BonjourParser.extractHeader(data: data)
        let (firstLine, headers) = BonjourParser.extractHeaders(headerData: headerData)
        if let length = headers["Content-Length"] {
            guard let body = body,body.count == Int(length) else {
                throw ParserError.incompleteBody
            }
        } else if let _ = body {
            throw ParserError.missingContentLength
        }
        return (firstLine, headers, body)
    }
}
