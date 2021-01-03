//
//  SampleHTTPClient.swift
//  sampleClient
//
//  Created by SATOSHI NAKAJIMA on 12/28/20.
//

import Foundation

class SampleHTTPClient: NSObject, BonjourConnectionDelegate {
    func on(responce: BonjourResponse, connection: BonjourConnection) {
        print("res", responce)
    }
}
