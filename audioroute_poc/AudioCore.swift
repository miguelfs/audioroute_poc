
import AVFoundation

enum AudioCoreError: Error { case NotSupportedCategoryError, UnnalowedEngineRewiring, MissingTracksError }

typealias FinishPlayingCallback = () -> Void

struct Track: Hashable {
    let node: AVAudioPlayerNode
    let file: AVAudioFile
}

func getFile(_ sampleRate: Double) -> AVAudioFile{
    let signal =  AudioSignal(sampleRate: sampleRate, waveform: .completion, startOffset: 0)
    let (_, url) = signal.generateFile()
    return try! AVAudioFile(forReading: url)
}

class AudioCore {
    private let file =  getFile(48000)
    private let session = AVAudioSession.sharedInstance()
    private var engine = AVAudioEngine.init()
//    private var tracks = Set<Track>()
    private var track: Track!
    private var onFinishPlaying: () -> Void
    private var audioRoute = AudioRoute()
    
    init(category: AVAudioSession.Category, completionHandler: @escaping (() -> Void)) {
        onFinishPlaying = completionHandler
        setNotifications()

        try! session.setCategory(category)
        try! session.setActive(true)
        
        try! setEngine(category)
        self.track = attachSignalSample()
        try! engine.start()
        print(engine.attachedNodes)
    }
    
    func update(_ category: AVAudioSession.Category) {
        print("1")
        engine.stop()

//        clearTracks()
        print("2")
        engine.detach(track.node)

        print("3")
        try! session.setActive(false)
        print("4")
        engine = AVAudioEngine.init()
        print("5")
        try! session.setCategory(category)
        print("6")
        try! setEngine(category)
        print("7")
        retachTracks()
        print("8")
        try! session.setActive(true)
        print("9")
        try! engine.start()
        print("10")
        print(engine.attachedNodes)
        print("11")
//        try! setEngine(value)
    }
    
    private func setNotifications() {}
    
    private func setEngine(_ mode: AVAudioSession.Category) throws {
        if engine.isRunning {
            throw AudioCoreError.UnnalowedEngineRewiring
        }
        switch mode {
        case .playback:
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
        case .playAndRecord:
            engine.connect(engine.inputNode, to: engine.mainMixerNode, format: engine.inputNode.inputFormat(forBus: 0))
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
        default:
            throw AudioCoreError.NotSupportedCategoryError
        }
    }
    
    private var sampleRate: Double {
//        return engine.inputNode.inputFormat(forBus: 0).sampleRate
        return 48000
    }

    private func rewind(_ track: Track) {
        let handler = {
//            if track.node.isPlaying {
                track.node.pause()
                self.rewind(track)
                self.onFinishPlaying()
        }
        track.node.scheduleFile(track.file, at: nil, completionHandler: handler)
    }
    
    private func attachSignalSample() -> Track {

        
        let playerNode = AVAudioPlayerNode()
        let track = Track(node: playerNode, file: file)
//        tracks.insert(track)
       engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format:
                        file.processingFormat)
        rewind(track)
        return track
    }
    
//    private func clearTracks() {
//        print("a")
//        engine.stop()
//        print("b")
//        for track in tracks {
//            print("d")
//            engine.detach(track.node)
//            print("e")
//        }
////        tracks.removeAll()
//    }
    
    private func retachTracks() {
//        for track in tracks {
            engine.attach(track.node)
            engine.connect(track.node, to: engine.mainMixerNode, format: engine.outputNode.outputFormat(forBus: 0))
//        }
    }
    
    func play() {
//        for track in tracks {
            track.node.play()
//        }
    }
    
    func pause() {
//        for track in tracks {
            track.node.pause()
//        }
    }
    
//    var t0: AVAudioTime {
//        for track in tracks {
//            let sampleRate = track.file.processingFormat.sampleRate
//            let sampleTime = AVAudioFramePosition(0.01 * sampleRate)
//            return AVAudioTime(hostTime: mach_absolute_time(), sampleTime: sampleTime, atRate: sampleRate)
////            return AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
//        }
//        let sampleTime = AVAudioFramePosition(0.01 * self.sampleRate)
//        return AVAudioTime(hostTime: mach_absolute_time(), sampleTime: sampleTime, atRate: sampleRate)
////        return AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
//}
}
