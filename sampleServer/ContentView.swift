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
    @ObservedObject var myServer = SampleHTTPServer()
    var service = BonjourService(type:"_samplehttp._tcp", port:8001)
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            List {
                ForEach(myServer.clients) { socket in
                    Text("Client")
                }
            }
            if myServer.isRunning {
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
            Button(action: {
                if let socket = myServer.clients.first {
                    var res = BonjourResponse(context: "push")
                    res.setBody(json: ["message":"I am pushing you"])
                    service.send(responce: res, to: socket)
                }
            }, label: {
                Text("Push")
            })
            if let image = myServer.image {
                Image(nsImage: NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height)))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
        }.onAppear() {
            service.delegate = myServer
            service.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
