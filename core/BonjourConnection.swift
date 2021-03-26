//
//  BonjourConnection.swift
//  mmRemote
//
//  Created by SATOSHI NAKAJIMA on 12/26/20.
//

import Foundation
import CocoaAsyncSocket

public protocol BonjourConnectionDelegate : NSObjectProtocol {
    // Only recponces not processed by callback (of send or call methos) will come here
    func connection(connection: BonjourConnection, responce res: BonjourResponse, context: String?)
}

public class BonjourConnection: NSObject, ObservableObject {
    @Published public var isConnected = false
    public weak var delegate: BonjourConnectionDelegate?
    private let service: NetService
    private var socket: GCDAsyncSocket? = nil
    private var buffer: Data? = nil
    public typealias CompletionHandler = (BonjourResponse, [String:Any]?)->()
    private var callbacks = [String:CompletionHandler]()
    
    public init(_ service: NetService) {
        self.service = service
        super.init()
        service.delegate = self
    }
    
    public func connect() {
        BonjourLogExtra("BonjourConnection:connect \(service.addresses?.count ?? 0)")
        if service.addresses?.count ?? 0 == 0 {
            service.resolve(withTimeout: 30.0)
            return
        }

        let socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        service.addresses?.forEach({ address in
            if self.socket == nil {
                do {
                    let _ = try socket.connect(toAddress: address)
                    self.socket = socket
                } catch {
                    BonjourLogWarning("BonjourConnection:connect failed \(error.localizedDescription)")
                }
            }
        })
    }
    
    public func disconnect() {
        BonjourLog("BonjourConnection:disconnect")
        if let socket = self.socket {
            socket.disconnect()
        }
    }
    
    public func send(req reqInput: BonjourRequest, callback: CompletionHandler? = nil) {
        BonjourLog("BonjourConnection:send \(reqInput)")
        var req = reqInput
        if let callback = callback {
            let context = UUID().uuidString
            callbacks[context] = callback
            req.headers["X-Context"] = context
        }
        socket?.write(req.headerData, withTimeout: -1.0, tag: 3)
        if let body = req.body {
            socket?.write(body, withTimeout: -1.0, tag: 3)
        }
    }
    
    public func call(_ name: String, params: [String:Any], callback: CompletionHandler? = nil) {
        BonjourLog("BonjourConnection:call \(name)")
        var req = BonjourRequest(path: "/api/\(name)", method: .Post)
        req.setBody(json: params)
        send(req: req, callback: callback)
    }
}

extension BonjourConnection : NetServiceDelegate {
    public func netServiceDidResolveAddress(_ sender: NetService) {
        BonjourLog("BonjourConnection:netServiceDidResolveAddress")
        connect()
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        BonjourLogError("BonjourConnection:netService:errorDict \(errorDict)")
    }
    
}

extension BonjourConnection : GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        BonjourLog("BonjourConnection:socket:didConnectToHost")
        isConnected = true
        sock.readData(withTimeout: -1, tag: 3)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        BonjourLog("BonjourConnection:socket:didDisconnect")
        socket = nil
        isConnected = false
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: 3)
        let buffer: Data
        if let prev = self.buffer {
            buffer = prev + data
            self.buffer = nil
        } else {
            buffer = data
        }
        innerSocket(sock, data: buffer)
    }
    
    private func innerSocket(_ sock: GCDAsyncSocket, data: Data) {
        do {
            let result = try BonjourParser.parse(data)
            let res = BonjourResponse(result: result)
            let context = res.headers["X-Context"]
            if let context = context,
               let callback = callbacks[context] {
                    callback(res, res.jsonBody)
                    callbacks.removeValue(forKey: context)
            } else {
                delegate?.connection(connection: self, responce: res, context: context)
            }
            if let extraData = result.extraData {
                BonjourLogExtra("BonjourConnection:innerSocket extra data \(extraData.count)")
                self.innerSocket(sock, data: extraData)
            }
        } catch {
            BonjourLogExtra("BonjourConnection:innerSocket buffering \(data.count)")
            buffer = data
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        // print("socket:didWriteDataWithTag")
    }
}
