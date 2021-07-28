
import SwiftUI



struct ContentView: View {
    @StateObject var audioController = AudioController();
    @State var isMicAvailable = false
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Audio App 🎙").font(.title)
            Text("Play audio and listen to yourself").font(.subheadline)
            ProgressView(value: audioController.progress)
            Toggle("isRecMode", isOn: $isMicAvailable).onChange(of: isMicAvailable) { value in
                audioController.audioMode = value == true ? .playAndRecord : .playback
            }
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
            List(audioController.mics) {
                if isMicAvailable {
                    Text($0.name)
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
