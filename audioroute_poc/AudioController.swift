//
//  AudioContent.swift
//  audioroute_poc
//
//  Created by Miguel Fernandes de Sousa on 20/07/21.
//

import Foundation
import AVFAudio

enum PlayerAction {
    case pause, play, stop, record
        }

enum PlayerState {
    case playing, recording, paused
        }

class AudioController: ObservableObject {
    @Published var isRecMode = false
    @Published var progress = 0.0
    @Published var hasAudioAttached = false
    @Published var playerState: PlayerState = .paused
    
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    
    init() {
//        let session = AVAudioSession.sharedInstance()
//        try! session.setCategory(.playback)
//        try! session.setActive(true)
    }
}
