//
//  BonjourService.swift
//  mmhmm
//
//  Created by SATOSHI NAKAJIMA on 12/25/20.
//  Copyright © 2020 mmhmm, inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol BonjourServiceDelegate: NSObjectProtocol {
    func on(reqeust: BonjourRequest, service: BonjourService, socket: GCDAsyncSocket)
    func on(function: String, service: BonjourService, params: [String:Any], socket: GCDAsyncSocket, context: String)
}

@objc class BonjourService : NSObject, ObservableObject {
    let type: String
    let port: UInt16
    weak var delegate:BonjourServiceDelegate?
    private var service:NetService? {
        didSet {
            isRunning = service != nil
        }
    }
    private var hostSocket = GCDAsyncSocket()
    @Published public var clients = [GCDAsyncSocket]()
    @Published public var isRunning = false
    private var buffers = [ObjectIdentifier:Data]()

    init(type: String, port: UInt16 = 0) {
        self.type = type
        self.port = port
    }
    
    func start() {
        hostSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        do {
            try hostSocket.accept(onPort: port)
            let service = NetService(domain: "local.", type: type, name: "", port: Int32(hostSocket.localPort))
            service.delegate = self
            service.publish()
            self.service = service
        } catch {
            print("### Error socket.accept failed", error)
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
    
    func send(responce: BonjourResponce, to socket: GCDAsyncSocket) {
        socket.write(responce.headerData, withTimeout: -1.0, tag: 3)
        if let body = responce.body {
            socket.write(body, withTimeout: -1.0, tag: 3)
        }
    }
}

extension BonjourService : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("socket:didAcceptNewSocket", newSocket)
        self.clients.append(newSocket)
        newSocket.delegate = self
        newSocket.delegateQueue = .main
        newSocket.readData(withTimeout: -1, tag: 3)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: 3)
        // WARNING: Following code assumes that we receive the HTTP request in one packet.
        var buffer: Data
        if let prev = buffers[sock.id] {
            buffer = prev
            buffer.append(data)
        } else {
            buffer = data
        }
        
        guard let req = BonjourRequest(data: buffer) else {
            print("buffering", buffer.count)
            buffers[sock.id] = buffer
            return
        }
        buffers.removeValue(forKey: sock.id)
        
        print("req:", req, sock.id)
        if let delegate = self.delegate {
            let components = req.path.components(separatedBy: "/")
            if components.count == 4, components[0] == "" && components[1] == "api" {
                print("API call", components[2], components[3])
                let json = req.jsonBody ?? [:]
                delegate.on(function: components[2], service: self, params: json, socket: sock, context: components[3])
                return
            }

            delegate.on(reqeust: req, service: self, socket: sock)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket:didConnectToHost")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socketDidDisconnect")
        buffers.removeValue(forKey: sock.id)
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
