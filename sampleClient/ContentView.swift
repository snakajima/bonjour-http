//
//  ContentView.swift
//  sampleClient
//
//  Created by SATOSHI NAKAJIMA on 12/27/20.
//

import SwiftUI

struct ContentView: View {
    let browser = BonjourBrowser("_sample._ctp")
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear() {
                browser.browseServices()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
