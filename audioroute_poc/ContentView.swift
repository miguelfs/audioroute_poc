//
//  ContentView.swift
//  audioroute_poc
//
//  Created by Miguel Fernandes de Sousa on 20/07/21.
//

import SwiftUI



struct ContentView: View {
    @State private var isRecMode = false
//    @State private var hasAudioAttached = false
//    @State private var playerState: PlayerState = .stop
    @ObservedObject var audioController = AudioController();
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Audio App 🎙").font(.title)
            Text("Record and play audio").font(.subheadline)
            ProgressView(value: audioController.progress)
            Toggle(isOn: $isRecMode) {
                Text("isRecMode")
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
