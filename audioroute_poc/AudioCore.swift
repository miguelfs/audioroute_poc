
import AVFoundation

enum AudioCoreError: Error { case NotSupportedCategoryError, UnnalowedEngineRewiring, MissingTracksError, TooManyOutputs}

typealias FinishPlayingCallback = () -> Void

struct Track: Hashable {
    let node: AVAudioPlayerNode
    let file: AVAudioFile
}

class AudioCore {
    private let session = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine.init()
    private var tracks = Set<Track>()
    private var onFinishPlaying: () -> Void
    private var audioRoute = AudioRoute()
    
    init(category: AVAudioSession.Category, completionHandler: @escaping (() -> Void)) {
        onFinishPlaying = completionHandler
        try! session.setCategory(category)
        try! session.setActive(true)
        setNotifications()
        
        try! setEngine(category)
        attachSignalSample()
        try! engine.start()
    }
    
    func updateCategory(_ value: AVAudioSession.Category) {
        engine.stop()
        try! session.setCategory(value)
        try! setEngine(value)
        try! engine.start()
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
            if engine.inputNode.numberOfOutputs > 1 {
                throw AudioCoreError.TooManyOutputs
            }
            if engine.inputNode.numberOfOutputs == 1 {
                engine.disconnectNodeOutput(engine.inputNode)
            }
        case .playAndRecord:
            engine.connect(engine.inputNode, to: engine.mainMixerNode, format: engine.inputNode.inputFormat(forBus: 0))
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
        default:
            throw AudioCoreError.NotSupportedCategoryError
        }
    }
    
    private var sampleRate: Double {
        return engine.inputNode.inputFormat(forBus: 0).sampleRate
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
    
    private func attachSignalSample() {
        let signal =  AudioSignal(sampleRate: sampleRate, waveform: .completion, startOffset: 0)
        let (_, url) = signal.generateFile()
        let file = try! AVAudioFile(forReading: url)
        
        let playerNode = AVAudioPlayerNode()
        let track = Track(node: playerNode, file: file)
        tracks.insert(track)
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: engine.outputNode.outputFormat(forBus: 0))
        rewind(track)
    }
    
    private func clearEngine() {
        engine.stop()
        engine.detach(engine.inputNode)
        engine.detach(engine.outputNode)
        for track in tracks {
            engine.detach(track.node)
        }
        tracks.removeAll()
    }
    
    func play() {
        for track in tracks {
            track.node.play()
        }
    }
    
    func pause() {
        for track in tracks {
            track.node.pause()
        }
    }
    
    var t0: AVAudioTime {
        for track in tracks {
            let sampleRate = track.file.processingFormat.sampleRate
            let sampleTime = AVAudioFramePosition(0.01 * sampleRate)
            return AVAudioTime(hostTime: mach_absolute_time(), sampleTime: sampleTime, atRate: sampleRate)
//            return AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
        }
        let sampleTime = AVAudioFramePosition(0.01 * self.sampleRate)
        return AVAudioTime(hostTime: mach_absolute_time(), sampleTime: sampleTime, atRate: sampleRate)
//        return AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
}
}
