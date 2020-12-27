//
//  ContentView.swift
//  sampleClient
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var browser = BonjourBrowser("_samplehttp._tcp")
    var body: some View {
        NavigationView {
            List {
                ForEach(browser.services) { service in
                    NavigationLink(
                        destination: ServiceView(service: service),
                        label: {
                            Text(service.name)
                        })
                }
            }
        }
        .onAppear() {
            browser.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
