//
//  BonjourConnection.swift
//  mmRemote
//
//  Created by SATOSHI NAKAJIMA on 12/26/20.
//

import Foundation
import CocoaAsyncSocket

class BonjourConnection: NSObject, ObservableObject {
    private let service:NetService
    private var socket:GCDAsyncSocket? = nil
    @Published var isConnected:Bool = false
    
    init(_ service:NetService) {
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
    
    func send(string: String) {
        let data = Data(string.utf8)
        socket?.write(data, withTimeout: -1.0, tag: 3)
    }

    func send(req: BonjourRequest) {
        //socket?.write()
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
        print("socket:didConnectToHost", self.isConnected, sock.connectedAddress, sock.localAddress, sock.localPort)
        isConnected = true
        sock.readData(withTimeout: -1, tag: 3)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket:didDisconnect")
        socket = nil
        isConnected = false
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let string = String(decoding:data, as:UTF8.self)
        print("socket:didRead", string)
        sock.readData(withTimeout: -1, tag: 3)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("socket:didWriteDataWithTag")
    }
}
