
import SwiftUI



struct ContentView: View {
    @StateObject var audioController = AudioController()
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Audio App 🎙").font(.title)
            Text("Play audio and listen to yourself").font(.subheadline)
            ProgressView(value: audioController.progress)
            Toggle("isRecMode", isOn: $audioController.isMicAvailable)
            HStack{
                Button(action: audioController.switchPlayPause) {
                    if audioController.playerState == .paused {
                        Text("▶️")
                    }
                    if audioController.playerState == .playing {
                        Text("⏸")
                    }
                }
            }
            List(audioController.mics) { mic in
                Button(action: {
                    if !mic.isActive {
                    audioController.selectMic(mic)
                    }
                }) {
                    if audioController.isMicAvailable {
                    Text(mic.name).foregroundColor(.accentColor)
                    if mic.isActive {
                        Image(systemName: "checkmark").foregroundColor(.accentColor)
                    }
                }
                }
            }.padding()
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
