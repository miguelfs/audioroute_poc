
import AVFoundation

enum AudioCoreError: Error { case NotSupportedCategoryError, UnnalowedEngineRewiring, MissingTracksError }

typealias FinishPlayingCallback = () -> Void

struct Track: Hashable {
    let node: AVAudioPlayerNode
    let file: AVAudioFile
}

class AudioCore {
    private let session = AVAudioSession.sharedInstance()
    private var engine = AVAudioEngine.init()
    private var track: Track!
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
        let onMediaReset = {
            self.engine.stop()
            try! self.session.setActive(false)
            // sometimes, detaching stucks without throwing error
            //self.engine.detach(self.track.node)
            self.engine = AVAudioEngine.init()
            try! AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try! self.setEngine(.playAndRecord)
//            self.engine.attach(self.track.node)
//            self.engine.connect(self.track.node, to: self.engine.mainMixerNode, format: self.engine.outputNode.outputFormat(forBus: 0))
//            self.rewind(self.track)
            try! self.session.setActive(true)
            try! self.engine.start()
            onRouteChange()
        }
        notifications = Notifications(onRouteChange: routeChange, onMediaReset: onMediaReset)
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
        track = Track(node: playerNode, file: file)
        engine.attach(track.node)
        engine.connect(track.node, to: engine.mainMixerNode, format: engine.outputNode.outputFormat(forBus: 0))
        rewind(track)
    }
    
    func play() {
            track.node.play()
    }
    
    func pause() {
            track.node.pause()
    }
}
