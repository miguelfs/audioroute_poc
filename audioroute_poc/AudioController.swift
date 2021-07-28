import AVFoundation

enum PlayerAction { case pause, play, stop, record }

enum PlayerState { case playing, paused }

enum RecorderState { case recording, paused }

struct Mic: Identifiable {
    let name: String
    let id = UUID()
}

func mapToggleToCategory(_ value: Bool) -> AVAudioSession.Category {
    return value == true ? .playAndRecord : .playback
}

class AudioController: ObservableObject {
    @Published var progress = 0.0
    @Published var playerState: PlayerState = .paused
    @Published var isMicAvailable = false {
        willSet(value) {
            self.playerState = .paused
            self.audioCore.update(mapToggleToCategory(value))
        }
    }
    @Published var mics = [Mic(name: "first mic"), Mic(name: "second mic")]
    var audioCore: AudioCore!
    
    init() {
        self.audioCore = AudioCore(category: mapToggleToCategory(self.isMicAvailable), completionHandler: {
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

