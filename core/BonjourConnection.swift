//
//  BonjourConnection.swift
//  mmRemote
//
//  Created by SATOSHI NAKAJIMA on 12/26/20.
//

import Foundation
import CocoaAsyncSocket

public protocol BonjourConnectionDelegate : NSObjectProtocol {
    func on(responce: BonjourResponse, connection: BonjourConnection)
}

public class BonjourConnection: NSObject, ObservableObject {
    @Published public var isConnected = false
    public weak var delegate: BonjourConnectionDelegate?
    private let service: NetService
    private var socket: GCDAsyncSocket? = nil
    private var buffer: Data? = nil
    public typealias CompletionHandler = (BonjourResponse, [String:Any])->()
    private var callbacks = [String:CompletionHandler]()
    
    public init(_ service: NetService) {
        self.service = service
        super.init()
        service.delegate = self
    }
    
    public func connect() {
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
    
    public func disconnect() {
        if let socket = self.socket {
            socket.disconnect()
        }
    }
    
    public func send(req: BonjourRequest) {
        socket?.write(req.headerData, withTimeout: -1.0, tag: 3)
        if let body = req.body {
            socket?.write(body, withTimeout: -1.0, tag: 3)
        }
    }
    
    public func call(_ name: String, params: [String:Any], callback: @escaping CompletionHandler) {
        let uuid = UUID().uuidString
        callbacks[uuid] = callback
        var req = BonjourRequest(path: "/api/\(name)/\(uuid)")
        req.setBody(json: params)
        send(req: req)
    }
}

extension BonjourConnection : NetServiceDelegate {
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress", sender.addresses!)
        connect()
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("netService:errorDict", errorDict)
    }
    
}

extension BonjourConnection : GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket:didConnectToHost")
        isConnected = true
        sock.readData(withTimeout: -1, tag: 3)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket:didDisconnect")
        socket = nil
        isConnected = false
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: 3)
        if let _ = self.buffer {
            buffer!.append(data)
        } else {
            buffer = data
        }
        do {
            let result = try BonjourParser.parseHeader(data: buffer!)
            let res = BonjourResponse(result: result)
            buffer = result.extraBody
            if let context = res.headers["X-Context"] {
                if let callback = callbacks[context] {
                    callback(res, res.jsonBody ?? [:])
                    callbacks.removeValue(forKey: context)
                    return
                }
            }
            
            delegate?.on(responce: res, connection: self)
        } catch {
            print("buffering", buffer!.count)
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        // print("socket:didWriteDataWithTag")
    }
}
