//
//  ContentView.swift
//  cardiowatchtest
//
//  Created by David A on 2021/11/18.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var cbManager = CBManager()
    
    var body: some View {
        Text(cbManager.state)
            .padding().onAppear {
                
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
