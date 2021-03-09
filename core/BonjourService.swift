//
//  BonjourService.swift
//  mmhmm
//
//  Created by SATOSHI NAKAJIMA on 12/25/20.
//  Copyright © 2020 mmhmm, inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public protocol BonjourServiceDelegate: NSObjectProtocol {
    func serviceRunningStateDidChange(_ service: BonjourService)
    func serviceClientsDidChange(_ service: BonjourService)
    func service(_ service: BonjourService, onRequest: BonjourRequest, socket: GCDAsyncSocket, context: String)
    func service(_ service: BonjourService, onCall: String, params: [String:Any], socket: GCDAsyncSocket, context: String)
}

extension GCDAsyncSocket {
    var uuid:UUID? { userData as? UUID }
}

public class BonjourService : NSObject {
    let type: String
    let port: UInt16
    public weak var delegate:BonjourServiceDelegate?
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

    public init(type: String, port: UInt16 = 0) {
        self.type = type
        self.port = port
    }
    
    public func start() {
        hostSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        do {
            try hostSocket.accept(onPort: port)
            let service = NetService(domain: "local.", type: type, name: "", port: Int32(hostSocket.localPort))
            service.delegate = self
            service.publish()
            self.service = service
        } catch {
            BonjourLogError("BonjourService:Error socket.accept failed \(error)")
        }
    }
    
    public func stop() {
        BonjourLog("BonjourService:stop \(self.service != nil)")
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
    
    public func send(responce: BonjourResponse, to socket: GCDAsyncSocket) {
        BonjourLog("BonjourService:send \(responce)")
        socket.write(responce.headerData, withTimeout: -1.0, tag: 3)
        if let body = responce.body {
            socket.write(body, withTimeout: -1.0, tag: 3)
        }
    }
    
    public func respond(to socket: GCDAsyncSocket, context: String, result: [String:Any], statusText: String? = nil) {
        var res = BonjourResponse(context: context)
        res.setBody(json: result)
        BonjourLog("BonjourService:respond \(res) \(context)")
        if let statusText = statusText {
            res.statusText = statusText
        }
        send(responce: res, to: socket)
    }
}

extension BonjourService : GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        BonjourLog("BonjourService:socket:didAcceptNewSocket \(newSocket)")
        self.clients.append(newSocket)
        newSocket.userData = UUID()
        newSocket.delegate = self
        newSocket.delegateQueue = .main
        newSocket.readData(withTimeout: -1, tag: 3)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: 3)

        guard let uuidSock = sock.uuid else {
            return
        }
        let buffer: Data
        if let prev = buffers[uuidSock] {
            buffer = prev + data
            buffers.removeValue(forKey: uuidSock)
        } else {
            buffer = data
        }

        self.innerSocket(sock, uuidSock: uuidSock, data: buffer)
    }
    
    private func innerSocket(_ sock: GCDAsyncSocket, uuidSock: UUID, data: Data) {
        do {
            let result = try BonjourParser.parse(data)
            let req = BonjourRequest(result: result)

            BonjourLog("BonjourService:innerSocket \(req)")
            if let delegate = self.delegate {
                let components = req.path.components(separatedBy: "/")
                if components.count == 3, components[0] == "", components[1] == "api", req.method == .Post {
                    let json = req.jsonBody ?? [:]
                    delegate.service(self, onCall: components[2], params: json, socket: sock, context: req.context)
                } else {
                    delegate.service(self, onRequest: req, socket: sock, context: req.context)
                }
            }
            if let extraData = result.extraData {
                BonjourLogExtra("BonjourService  extra data \(extraData.count)")
                self.innerSocket(sock, uuidSock: uuidSock, data: extraData)
            }
        } catch {
            BonjourLogExtra("BonjourService  buffering \(data.count)")
            buffers[uuidSock] = data
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
    }
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        BonjourLog("BonjourService:socket:didConnectToHost")
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        BonjourLog("BonjourService:socketDidDisconnect")
        if let uuid = sock.uuid { // dealing with the its own socket
            buffers.removeValue(forKey: uuid)
        }
        clients = clients.filter { $0 != sock }
    }
}

extension BonjourService : NetServiceDelegate {
    public func netServiceDidPublish(_ sender: NetService) {
        BonjourLog("BonjourService:netServiceDidPublish")
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        BonjourLogError("BonjourService:netService:didNotPublish \(errorDict)")
    }
}
