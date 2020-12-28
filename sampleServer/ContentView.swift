//
//  ContentView.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import SwiftUI
import CocoaAsyncSocket

extension GCDAsyncSocket : Identifiable {
}

struct ContentView: View {
    @ObservedObject var service = BonjourService(type:"_samplehttp._tcp", port:8001)
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            List {
                ForEach(service.clients) { socket in
                    Text("Client")
                }
            }
            if service.isRunning {
                Button(action: {
                    service.stop()
                }, label: {
                    Text("Stop")
                })
            } else {
                Button(action: {
                    service.start()
                }, label: {
                    Text("Start")
                })
            }
        }.onAppear() {
            service.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
