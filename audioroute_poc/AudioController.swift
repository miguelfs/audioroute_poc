
import Foundation
import AVFoundation

enum PlayerAction { case pause, play, stop, record }

enum PlayerState { case playing, paused }

enum RecorderState { case recording, paused }

enum AudioMode { case playAndRecord, playback }

struct Mic: Identifiable, Hashable {
    let name: String
    var isActive: Bool = false
    let id = UUID()
}

func mapModeToCategory(mode value: AudioMode) -> AVAudioSession.Category {
    let category: AVAudioSession.Category = value == .playAndRecord ? .playAndRecord : .playback
    return category
}

class AudioController: ObservableObject {
    @Published var progress = 0.0
    @Published var playerState: PlayerState = .paused
    @Published var mics = [Mic(name: "first mic"), Mic(name: "second mic")]
    
    @Published var audioMode: AudioMode = .playback {
        willSet(value) {            
            self.audioCore.updateCategory(mapModeToCategory(mode: value))
        }
    }
    var audioCore: AudioCore!
    init() {
        self.audioCore = AudioCore(category: mapModeToCategory(mode: audioMode), completionHandler: {
            DispatchQueue.main.async {
                self.playerState = .paused
            }
        })
        mics = audioCore.audioRoute.getAvailableInputs().map{Mic(name: $0, isActive: $0 == getActiveMic())}
    }
    
    func getActiveMic() -> String {
        return audioCore.audioRoute.getCurrentInput()
    }
    
    func selectMic(_ mic: Mic) {
        audioCore.audioRoute.setInput(portName: mic.name)
        for i in 0..<mics.count {
            mics[i].isActive = mic.id == mics[i].id ? true : false
        }
    }
    
    func switchPlayPause() {
        if playerState == .paused {
            audioCore.play()
            playerState = .playing
            return
        }
        if playerState == .playing {
            audioCore.pause()
            playerState = .paused
        }
    }
}

