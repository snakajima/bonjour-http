//
//  BonjourConnection.swift
//  mmRemote
//
//  Created by SATOSHI NAKAJIMA on 12/26/20.
//

import Foundation
import CocoaAsyncSocket

protocol BonjourConnectionDelegate : NSObjectProtocol {
    func on(responce: BonjourResponse, connection: BonjourConnection)
}

class BonjourConnection: NSObject, ObservableObject {
    @Published var isConnected = false
    public weak var delegate: BonjourConnectionDelegate?
    private let service: NetService
    private var socket: GCDAsyncSocket? = nil
    private var buffer: Data? = nil
    typealias CompletionHandler = (BonjourResponse, [String:Any])->()
    private var callbacks = [String:CompletionHandler]()
    
    init(_ service: NetService) {
        self.service = service
        super.init()
        service.delegate = self
    }
    
    func connect() {
        if service.addresses?.count ?? 0 == 0 {
            service.resolve(withTimeout: 30.0)
            return
        }

        let socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        service.addresses?.forEach({ address in
            if self.socket == nil, let _ = try? socket.connect(toAddress: address) {
                self.socket = socket
            }
        })
    }
    
    func disconnect() {
        if let socket = self.socket {
            socket.disconnect()
        }
    }
    
    func send(req: BonjourRequest) {
        socket?.write(req.headerData, withTimeout: -1.0, tag: 3)
        if let body = req.body {
            socket?.write(body, withTimeout: -1.0, tag: 3)
        }
    }
    
    func call(_ name: String, params: [String:Any], callback: @escaping CompletionHandler) {
        let uuid = UUID().uuidString
        callbacks[uuid] = callback
        var req = BonjourRequest(path: "/api/\(name)/\(uuid)")
        req.setBody(json: params)
        send(req: req)
    }
}

extension BonjourConnection : NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress", sender.addresses!)
        connect()
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("netService:errorDict", errorDict)
    }
    
}

extension BonjourConnection : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket:didConnectToHost")
        isConnected = true
        sock.readData(withTimeout: -1, tag: 3)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket:didDisconnect")
        socket = nil
        isConnected = false
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: 3)
        if let _ = self.buffer {
            buffer!.append(data)
        } else {
            buffer = data
        }
        guard let res = BonjourResponse(data: buffer!) else {
            print("buffering", buffer!.count)
            return
        }
        buffer = nil
        if let context = res.headers["X-Context"] {
            if let callback = callbacks[context] {
                callback(res, res.jsonBody ?? [:])
                callbacks.removeValue(forKey: context)
                return
            }
        }
        
        delegate?.on(responce: res, connection: self)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        // print("socket:didWriteDataWithTag")
    }
}
