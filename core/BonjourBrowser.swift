//
//  BonjourConnection.swift
//  mmRemote
//
//  Created by SATOSHI NAKAJIMA on 12/26/20.
//

import Foundation

extension NetService : Identifiable {
}

public class BonjourBrowser: NSObject, ObservableObject {
    let type: String
    private var serviceBrowser = NetServiceBrowser()
    @Published public var services = [NetService]()
    
    public init(_ type: String) {
        self.type = type
    }

    public func start() {
        services.removeAll()
        serviceBrowser.delegate = self
        serviceBrowser.schedule(in: .main, forMode: .common)
        serviceBrowser.searchForServices(ofType: type, inDomain: "local.")
    }
}

extension BonjourBrowser : NetServiceBrowserDelegate {
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        BonjourLog("BonjourBrowser:netServiceBrowser:didFind \(service)")
        services.append(service)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services = services.filter { $0 != service }
        BonjourLog("BonjourBrowser:netServiceBroser:didRemove \(service), \(services.count)")
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        BonjourLog("BonjourBrowser:netServiceBrowserDidStopSearch")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        BonjourLogError("BonjourBrowser:netServiceBrowser:didNotSearch \(errorDict)")
    }
}
