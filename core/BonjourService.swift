//
//  BonjourService.swift
//  mmhmm
//
//  Created by SATOSHI NAKAJIMA on 12/25/20.
//  Copyright © 2020 mmhmm, inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

@objc class BonjourService : NSObject, ObservableObject {
    let type:String
    private var service:NetService? {
        didSet {
            isRunning = service != nil
        }
    }
    private var hostSocket = GCDAsyncSocket()
    private var clientSocket:GCDAsyncSocket?
    @Published public var isRunning = false

    init(type:String) {
        self.type = type
    }
    
    func start() {
        hostSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        do {
            try hostSocket.accept(onPort: 0)
            print("socket created")
            let service = NetService(domain: "local.", type: type, name: "", port: Int32(hostSocket.localPort))
            service.delegate = self
            service.publish()
            self.service = service
        } catch {
            print("socket.accept failed", error)
        }
    }
    
    func stop() {
        if let service = self.service {
            service.stop()
            service.delegate = nil
            self.service = nil
        }
    }
    
    func send(string: String) {
        let data = Data(string.utf8)
        print(hostSocket, clientSocket!)
        clientSocket?.write(data, withTimeout: -1.0, tag: 3)
    }
}

extension BonjourService : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("socket:didAcceptNewSocket", newSocket)
        self.clientSocket = newSocket
        newSocket.delegate = self
        newSocket.delegateQueue = .main
        newSocket.readData(withTimeout: -1, tag: 3)
        //newSocket.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 3)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let string = String(decoding:data, as:UTF8.self)
        print("socket:didRead:withTag", data, tag, string, sock)
        sock.readData(withTimeout: -1, tag: 3)
        
        send(string: "How are you?")
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("socket:didWriteDataWithTag")
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket:didConnectToHost")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socketDidDisconnect")
    }
}

extension BonjourService : NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        print("netServiceDidPublish")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("netService:didNotPublish", errorDict)
    }
}
