//
//  ContentView.swift
//  Family Cinema Pro
//
//  Tela principal do app
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        StreamingView()
            .preferredColorScheme(.dark)
            .statusBarHidden()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
