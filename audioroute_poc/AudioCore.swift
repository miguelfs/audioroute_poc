
import AVFoundation

enum AudioCoreError: Error { case NotSupportedCategoryError, UnnalowedEngineRewiring, MissingTracksError, MissingRouteError }

typealias FinishPlayingCallback = () -> Void

struct Track: Hashable {
    let node: AVAudioPlayerNode
    let file: AVAudioFile
}

class AudioCore {
    private let session = AVAudioSession.sharedInstance()
    private var engine = AVAudioEngine.init()
    private var tracks = Set<Track>()
    private var onFinishPlaying: () -> Void
    public var audioRoute = AudioRoute()
    private var notifications: Notifications!
    var routeChange: () -> Void = {}
    init(category: AVAudioSession.Category,
         completionHandler: @escaping (() -> Void),
         onRouteChange: @escaping (() -> Void),
         onPreemptPlayback: @escaping (() -> Void)) {
        onFinishPlaying = completionHandler
//        try! session.setCategory(category)
        try! session.setActive(true)
        routeChange = {
//            var category = AVAudioSession.sharedInstance().category
//            if category == .soloAmbient {
//                category = .playback
//                onPreemptPlayback()
//            } else {
                self.updateCategory(category)
//            }
            onRouteChange()
        }
        notifications = Notifications(onRouteChange: routeChange)

        try! setEngine(category)
        
        attachSignalSample()
        try! engine.start()
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
        if audioRoute.getCurrentInput() == "" || audioRoute.getCurrentOutput() == "" {
            throw AudioCoreError.MissingRouteError
        }
//        if engine.outputNode.outputFormat(forBus: 0).sampleRate == 0 &&
//            engine.inputNode.inputFormat(forBus: 0).sampleRate == 0 {
//            clearTracks()
//            engine = AVAudioEngine.init()
//        }
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
    
    private func clearTracks() {
        for track in tracks {
            engine.detach(track.node)
        }
        tracks.removeAll()
    }
    
    func play() throws {
//        if audioRoute.getCurrentInput() == "" || audioRoute.getCurrentOutput() == "" {
////            throw AudioCoreError.MissingRouteError
//            routeChange()
//        }
    //    print(AVAudioSession.sharedInstance().category)
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
