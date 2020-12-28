//
//  ContentView.swift
//  sampleServer
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var service = BonjourService(type:"_samplehttp._tcp")
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
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
