
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

