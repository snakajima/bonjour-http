//
//  SampleHTTPClient.swift
//  sampleClient
//
//  Created by SATOSHI NAKAJIMA on 12/28/20.
//

import Foundation

class SampleHTTPClient: NSObject, BonjourConnectionDelegate {
    func connection(connection: BonjourConnection, responce res: BonjourResponse, context: String?) {
        if let context = context, context == "push" {
            print("pushed", res)

        } else {
            print("unhandled response", res)
        }
    }
}
