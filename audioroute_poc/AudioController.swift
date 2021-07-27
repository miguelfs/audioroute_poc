
import Foundation
import AVFoundation

enum PlayerAction { case pause, play, stop, record }

enum PlayerState { case playing, paused }

enum RecorderState { case recording, paused }

enum AudioMode { case playAndRecord, playback }

struct Mic: Identifiable {
    let name: String
    let id = UUID()
}

class AudioController: ObservableObject {
    @Published var progress = 0.0
    @Published var countAudiosAttached = 0
    @Published var playerState: PlayerState = .paused
    @Published var mics = [Mic(name: "first mic"), Mic(name: "second mic")]
    
    @Published var audioMode: AudioMode = .playAndRecord {
        didSet(value) {
            let category: AVAudioSession.Category = value == .playAndRecord ? .playback : .playAndRecord
            self.audioCore.setCategory(category)
        }
    }
    
    var audioCore: AudioCore!
    
    init() {
        self.audioCore = AudioCore(completionHandler: {
            self.playerState = .paused
        })
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

