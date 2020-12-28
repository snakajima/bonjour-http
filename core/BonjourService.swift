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
    let port:UInt16
    private var service:NetService? {
        didSet {
            isRunning = service != nil
        }
    }
    private var hostSocket = GCDAsyncSocket()
    @Published public var clients = [GCDAsyncSocket]()
    @Published public var isRunning = false

    init(type: String, port: UInt16 = 0) {
        self.type = type
        self.port = port
    }
    
    func start() {
        hostSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        do {
            try hostSocket.accept(onPort: port)
            print("socket created", hostSocket.localPort)
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
            clients.forEach { (socket) in
                socket.disconnect()
            }
            clients.removeAll()
            service.stop()
            service.delegate = nil
            self.service = nil
        }
    }
    
    func send(to socket: GCDAsyncSocket, string: String) {
        let data = Data(string.utf8)
        socket.write(data, withTimeout: -1.0, tag: 3)
    }
}

extension BonjourService : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("socket:didAcceptNewSocket", newSocket)
        self.clients.append(newSocket)
        newSocket.delegate = self
        newSocket.delegateQueue = .main
        newSocket.readData(withTimeout: -1, tag: 3)
        //newSocket.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 3)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let string = String(decoding:data, as:UTF8.self)
        print("socket:didRead:withTag", data, tag, string, sock)
        sock.readData(withTimeout: -1, tag: 3)
        
        // WARNING: Following code assumes that we receive the HTTP request in one packet.
        guard let http = HTTPHeader(string: string) else {
            return
        }
        print("http", http)

        send(to: sock, string: "How are you?")
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("socket:didWriteDataWithTag")
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket:didConnectToHost")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socketDidDisconnect")
        clients = clients.filter { $0 != sock }
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
