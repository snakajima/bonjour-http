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
    private let client = SampleHTTPClient()
    init(service:NetService) {
        self.service = service
        self.connection = BonjourConnection(service)
        self.connection.delegate = client
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
                let req = BonjourRequest(path: "/foo")
                connection.send(req: req)
            }, label: {
                Text("Get")
            })
            Button(action: {
                var req = BonjourRequest(path: "/bar", method: "POST")
                req.setBody(string: "Hello World")
                connection.send(req: req)
            }, label: {
                Text("Post")
            })
            Button(action: {
                var req = BonjourRequest(path: "/json")
                let json = [
                    "params": [
                        "message":"Hello World",
                        "foo": 10,
                        "bar": [1, 2, 3]
                    ]
                ]
                req.setBody(json: json)
                connection.send(req: req)
            }, label: {
                Text("Post JSON")
            })
            Button(action: {
                let json = [
                    "params": [
                        "message":"Hello World",
                        "foo": 10,
                        "bar": [1, 2, 3]
                    ]
                ]
                connection.call(name: "foo", params: json) { (res, json) in
                    print("foo callback", json ?? "N/A", res.statusText)
                }
            }, label: {
                Text("HTTP Call")
            })
            Button(action: {
                connection.call(name: "bad", params: [:]) { (res, json) in
                    print("foo callback", json ?? "N/A", res.statusText)
                }
            }, label: {
                Text("Bad HTTP Call")
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
