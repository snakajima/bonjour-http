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
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?

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
                for i in 0..<8 {
                    let req = BonjourRequest(path: "/foo")
                    connection.send(req: req) { (res, json) in
                        BonjourLog("callback \(i) \(res.statusText)")
                    }
                }
            }, label: {
                Text("Get")
            })
            Button(action: {
                var req = BonjourRequest(path: "/bar", method: .Post)
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
                let json:[String:Any] = [
                    "delay": 0.2,
                    "params": [
                        "message":"Hello World",
                        "foo": 10,
                        "bar": [1, 2, 3]
                    ]
                ]
                connection.call("foo", params: json) { (res, json) in
                    if res.isSuccess {
                        print("foo callback", json ?? [:], res.statusText, res.status)
                    } else {
                        print("foo failed", json ?? [:], res.statusText, res.status)
                    }
                }
            }, label: {
                Text("HTTP Call")
            })
            Button(action: {
                let json = [
                    "params": [
                        "message":"Hello World",
                        "foo": 10,
                        "bar": [1, 2, 3]
                    ]
                ]
                connection.call("foo", params: [:]) { (res, _) in print( "1", res.isSuccess ) }
                connection.call("foo", params: ["delay":1.0]) { (res, _) in print( "2", res.isSuccess ) }
                connection.call("foo", params: ["delay":0.5]) { (res, _) in print( "3", res.isSuccess ) }
                connection.call("foo", params: [:]) { (res, _) in print( "4", res.isSuccess ) }
                connection.call("foo", params: json) { (res, _) in print( "5", res.isSuccess ) }
                connection.call("foo", params: json) { (res, _) in print( "6", res.isSuccess ) }
                connection.call("foo", params: json) { (res, _) in print( "7", res.isSuccess ) }
                connection.call("foo", params: json) { (res, _) in print( "8", res.isSuccess ) }
            }, label: {
                Text("HTTP Calls")
            })
            Button(action: {
                connection.call("bad", params: [:]) { (res, json) in
                    if res.isSuccess {
                        print("bad callback", json ?? [:], res.statusText, res.status)
                    } else {
                        print("bad failed", json ?? [:], res.statusText, res.status)
                    }
                }
            }, label: {
                Text("Bad HTTP Call")
            })
            Button(action: {
                BonjourLog("photo")
                self.showingImagePicker = true
            }, label: {
                Text("Image")
            })
        }
        .onAppear() {
            self.connection.connect()
        }
        .onDisappear() {
            self.connection.disconnect()
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage, content: {
            ImagePicker(image: $inputImage)
        })
    }
    func loadImage() {
        //guard let inputImage = inputImage else { return }
        print("loadImage")
        guard let data = inputImage?.jpegData(compressionQuality: 0.7) else {
            return
        }
        var req = BonjourRequest(path: "/image", method: .Post)
        req.setBody(data: data, type: "image/jpeg")
        connection.send(req: req) { (res, json) in
            print("image posted: \(res.statusText)")
        }
        //image = Image(uiImage: inputImage)
    }
}
