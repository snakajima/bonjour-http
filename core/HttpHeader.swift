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
        return nil
    }
}
