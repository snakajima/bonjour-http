//
//  BonjourConnection.swift
//  mmRemote
//
//  Created by SATOSHI NAKAJIMA on 12/26/20.
//

import Foundation

extension NetService : Identifiable {
}

class BonjourBrowser: NSObject, ObservableObject {
    let type:String
    var serviceBrowser = NetServiceBrowser()
    @Published var services = [NetService]()
    
    init(_ type:String) {
        self.type = type
    }

    func browseServices() {
        services.removeAll()
        serviceBrowser.delegate = self
        print("step 1")
        serviceBrowser.schedule(in: .main, forMode: .common)
        print("step 2")
        serviceBrowser.searchForServices(ofType: type, inDomain: "local.")
        print("step 3")
    }
}

extension BonjourBrowser : NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("netServiceBrowser:didFind", service)
        services.append(service)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("netServiceBroser:didRemove")
        services = services.filter { $0 !== service }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserDidStopSearch")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("netServiceBrowser:didNotSearch", errorDict)
    }
}
