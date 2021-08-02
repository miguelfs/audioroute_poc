
import AVFoundation

enum AudioCoreError: Error { case NotSupportedCategoryError, UnnalowedEngineRewiring, MissingTracksError }

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
    public var audioRoute = AudioRoute()
    private var notifications: Notifications!
    
    init(category: AVAudioSession.Category,
         completionHandler: @escaping (() -> Void),
         onRouteChange: @escaping (() -> Void)) {
        onFinishPlaying = completionHandler
        try! session.setActive(true)
        let routeChange = {
            self.updateCategory()
            onRouteChange()
        }
        notifications = Notifications(onRouteChange: routeChange)
        try! setEngine(category)
        attachSignalSample()
        try! engine.start()
    }
    
    func updateCategory() {
        let value = AVAudioSession.sharedInstance().category
        updateCategory(value)
    }
    
    func updateCategory(_ value: AVAudioSession.Category) {
        engine.stop()
        try! session.setCategory(value)
        try! setEngine(value)
        try! session.setActive(true)
        try! engine.start()
        
    }
        
    private func setEngine(_ mode: AVAudioSession.Category) throws {
        if engine.isRunning {
            throw AudioCoreError.UnnalowedEngineRewiring
        }
        switch mode {
        case .playback:
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))
            engine.disconnectNodeOutput(engine.inputNode)
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
}
