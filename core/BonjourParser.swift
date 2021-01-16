//
//  BonjourParser.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 12/28/20.
//

import Foundation

class BonjourParser {
    enum ParserError : Error {
        case incompleteHeader
        case incompleteBody
        case missingContentLength
    }
    struct Result {
        let firstLine: String
        let headers: [String:String]
        var body: Data? = nil
        var extraData: Data? = nil
    }
    
    private static func extractHeader(data:Data) throws -> (Data, Data?) {
        let rows = data.split(separator: 0x0a)
        var headerLength = 0
        var counter = 0
        rows.forEach { (row) in
            if row.count == 1 && headerLength == 0
                && String(decoding:row, as:UTF8.self) == "\r" {
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
    
    private static func parseHeader(headerData: Data) -> Result {
        let string = String(decoding: headerData, as: UTF8.self)
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
        return Result(firstLine: firstLine, headers: headers)
    }
    
    static func parse(_ data: Data) throws -> Result {
        let (headerData, body) = try BonjourParser.extractHeader(data: data)
        var result = BonjourParser.parseHeader(headerData: headerData)
        if let contentLength = result.headers["Content-Length"],
           let length = Int(contentLength) {
            guard let bodyAll = body, bodyAll.count >= length else {
                throw ParserError.incompleteBody
            }
            if bodyAll.count > length {
                result.body = bodyAll.subdata(in: 0..<length)
                result.extraData = bodyAll.subdata(in: length..<bodyAll.count)
            } else {
                result.body = bodyAll
            }
        } else if let extraData = body {
            result.extraData = extraData
        }
        return result
    }
}
