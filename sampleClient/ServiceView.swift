//
//  ConnectionView.swift
//  sampleClient
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import SwiftUI

struct ServiceView: View {
    let service:NetService
    let connection:BonjourConnection
    init(service:NetService) {
        self.service = service
        self.connection = BonjourConnection(service)
    }
    
    var body: some View {
        VStack {
            Text(service.name)
        }
        .onAppear() {
            self.connection.connect()
        }
        .onDisappear() {
            self.connection.disconnect()
        }
    }
}
