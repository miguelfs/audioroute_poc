
import AVFoundation

enum AudioCoreError: Error { case NotSupportedCategoryError, UnnalowedEngineRewiring }

typealias FinishPlayingCallback = () -> Void

class AudioCore {
    private let session = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine.init()
    private var players = Set<AVAudioPlayerNode>()
    private var onFinishPlaying: () -> Void
    private var audioRoute = AudioRoute()
    
    init(completionHandler: @escaping (() -> Void)) {
        onFinishPlaying = completionHandler
        try! session.setCategory(.playback)
        try! session.setActive(true)
        setNotifications()
        
        try! setEngine(.playback)
        attachSignalSample()
        try! engine.start()
    }
    
    func setCategory(_ value: AVAudioSession.Category) {
        try! session.setCategory(value)
    }
    
    private func setNotifications() {}
    
    private func setEngine(_ mode: AVAudioSession.Category) throws {
        if engine.isRunning {
            throw AudioCoreError.UnnalowedEngineRewiring
        }
        if mode == .playback {
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
            return
        }
        if mode == .playAndRecord {
            engine.connect(engine.inputNode, to: engine.mainMixerNode, format: engine.inputNode.inputFormat(forBus: 0))
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
            return
        }
        throw AudioCoreError.NotSupportedCategoryError
    }
    
    private var sampleRate: Double {
        return engine.inputNode.inputFormat(forBus: 0).sampleRate
    }
    
    private func attachSignalSample() {
        let signal = AudioSignal(sampleRate: sampleRate, soundDuration: 3)
        let (_, url) = signal.generateFile()
        let file = try! AVAudioFile(forReading: url)
        //        let buffer = signal.getAsPCMBuffer(audioFormat: engine.mainMixerNode.inputFormat(forBus: 0))
        
        let playerNode = AVAudioPlayerNode()
        players.insert(playerNode)
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: engine.outputNode.outputFormat(forBus: 0))
        playerNode.scheduleFile(file, at: AVAudioTime(hostTime: 0), completionHandler: nil)
        //        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }
    
    private func clearEngine() {
        engine.stop()
        engine.detach(engine.inputNode)
        engine.detach(engine.outputNode)
        for player in players {
            engine.detach(player)
        }
    }
    
    func play() {
        //        try! engine.start()
        for player in players {
            player.play()
        }
    }
    
    func pause() {
        for player in players {
            player.pause()
        }
    }
}
