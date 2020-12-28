//
//  ConnectionView.swift
//  sampleClient
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import SwiftUI

struct ServiceView: View {
    @Environment(\.presentationMode) var presentation
    let service:NetService
    @ObservedObject var connection:BonjourConnection
    init(service:NetService) {
        self.service = service
        self.connection = BonjourConnection(service)
    }
    
    var body: some View {
        VStack {
            Text(service.name)
            if connection.isConnected {
                Text("Connected")
                    .onDisappear() {
                        print("disconnected")
                        self.presentation.wrappedValue.dismiss()
                    }
            }
            Button(action: {
                connection.send(string: "Hello World")
            }, label: {
                Text("Hello")
            })
        }
        .onAppear() {
            self.connection.connect()
        }
        .onDisappear() {
            self.connection.disconnect()
        }
    }
}
