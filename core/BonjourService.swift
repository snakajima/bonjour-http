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
    func serviceRunningStateDidChange(_ service: BonjourService)
    func serviceClientsDidChange(_ service: BonjourService)
    func service(_ service: BonjourService, onRequest: BonjourRequest, socket: GCDAsyncSocket)
    func service(_ service: BonjourService, onCall: String, params: [String:Any], socket: GCDAsyncSocket, context: String)
}

extension GCDAsyncSocket {
    var uuid:UUID? { userData as? UUID }
}

@objc class BonjourService : NSObject {
    let type: String
    let port: UInt16
    weak var delegate:BonjourServiceDelegate?
    private var service:NetService? {
        didSet {
            isRunning = service != nil
            delegate?.serviceRunningStateDidChange(self)
        }
    }
    private var hostSocket = GCDAsyncSocket()
    public var clients = [GCDAsyncSocket]() {
        didSet {
            delegate?.serviceClientsDidChange(self)
        }
    }
    public var isRunning = false
    private var buffers = [UUID:Data]()

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
    
    func send(responce: BonjourResponse, to socket: GCDAsyncSocket) {
        socket.write(responce.headerData, withTimeout: -1.0, tag: 3)
        if let body = responce.body {
            socket.write(body, withTimeout: -1.0, tag: 3)
        }
    }
    
    func respond(to socket: GCDAsyncSocket, context: String, result: [String:Any], statusText: String? = nil) {
        var res = BonjourResponse()
        res.headers["X-Context"] = context
        res.setBody(json: result)
        if let statusText = statusText {
            res.statusText = statusText
        }
        send(responce: res, to: socket)
    }
}

extension BonjourService : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("socket:didAcceptNewSocket", newSocket)
        self.clients.append(newSocket)
        newSocket.userData = UUID()
        newSocket.delegate = self
        newSocket.delegateQueue = .main
        newSocket.readData(withTimeout: -1, tag: 3)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: 3)
        
        guard let uuidSock = sock.uuid else {
            return
        }
        
        var buffer: Data
        if let prev = buffers[uuidSock] {
            buffer = prev
            buffer.append(data)
        } else {
            buffer = data
        }
        
        guard let req = BonjourRequest(data: buffer) else {
            print("buffering", buffer.count)
            buffers[uuidSock] = buffer
            return
        }
        buffers.removeValue(forKey: uuidSock)
        
        print("req:", req, uuidSock)
        if let delegate = self.delegate {
            let components = req.path.components(separatedBy: "/")
            if components.count == 4, components[0] == "" && components[1] == "api" {
                print("API call", components[2], components[3])
                let json = req.jsonBody ?? [:]
                delegate.service(self, onCall: components[2], params: json, socket: sock, context: components[3])
                return
            }

            delegate.service(self, onRequest: req, socket: sock)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket:didConnectToHost")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socketDidDisconnect")
        if let uuid = sock.uuid { // dealing with the its own socket
            buffers.removeValue(forKey: uuid)
        }
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
