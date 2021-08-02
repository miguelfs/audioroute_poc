import AVFoundation

typealias InterruptionAction = (Notification) -> Void
typealias Handler = (AudioCore) -> InterruptionAction

struct Notifications {
    var onRouteChange: (() -> Void)!
    var onMediaReset: (() -> Void)!
    

    init(onRouteChange: @escaping(() -> Void), onMediaReset: @escaping(() -> Void)) {
        self.onRouteChange = onRouteChange
        self.onMediaReset = onMediaReset
        print("settou on route change")
        setupNotifications()

    }
    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: self.handleOnRouteChange())
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil, using: self.handleNotificationInterruption())
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereLostNotification, object: nil, queue: nil, using: self.handleMediaOsLost())
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil, using: self.handleMediaOsReset())
    }
    
    func handleMediaOsReset() -> InterruptionAction {
        return { (_) in
            print("handleMediaOsReset")
            onMediaReset()
        }
    }
    
    func handleMediaOsLost() -> InterruptionAction {
        return { (_) in
            print("handleMediaOsLost")
        }
    }
    
    func handleNotificationInterruption() -> InterruptionAction {
        print("interruption started")
        return { (notification) in
            guard
                let info = notification.userInfo,
                let interruptionKey = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionKey)
            else {
                print("nothing to do on interruption notification")
                return
            }
            switch interruptionType {
            case .began:
                print("interruption began")
                recordingInterruptionHandler()
                playInterruptionBeganHandler()
            case .ended:
                print("interruption ended")
                // there is no handle to recording. Once is settle to not interrupt,
                // otherwise if is not available on version, it will stop recording
                // on began and does nothing on ended
                playInterruptionEndedHandler()
            default:
                return
            }
        }
    }
    
    private func playInterruptionBeganHandler() {
        print("pausing audioEngine due to interruption")
        //control.pause()
    }
    
    private func playInterruptionEndedHandler() {
        print("play interruption ended handler")
    }
    
    private func recordingInterruptionHandler() {
        print("recording interruption handler")
    }
    
    func handleOnRouteChange() -> InterruptionAction {
        return { (notification) in
            guard
                let info = notification.userInfo,
                let reasonKey = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: reasonKey)
            else {
                print("nothing to do on route change")
                return
            }
            
            switch reason {
            // new device became available(e.g. headphones have been plugged in).
            case .newDeviceAvailable:
                print("handleOnRouteChange: new device available")
                newDeviceAvailableHandler()
            case .oldDeviceUnavailable:
                print("handleOnRouteChange: old device available")
                oldDeviceUnavailableHandler(info: info)
            case .categoryChange:
                print("category = \(AVAudioSession.sharedInstance().category)")
                print(" = \(AVAudioSession.sharedInstance().categoryOptions)")
                print("handleOnRouteChange: category change")
            case .noSuitableRouteForCategory:
                print("handleOnRouteChange: no suitable route for category")
            case .override:
                print("handleOnRouteChange: override")
            case .unknown:
                print("handleOnRouteChange: unknown")
            // wake from sleep will reset everything again
            case .wakeFromSleep:
                setupDefaultOfResources()
                return
            default:
                print("router reason \(reason) does not match any mapped")
                return
            }
        }
    }
    
    private func setupDefaultOfResources() {
        print("setup default of resources")
    }
    
    private func newDeviceAvailableHandler() {
        print("headphone or bluetooth detected...")
        onRouteChange()
        return
    }
    
    private func oldDeviceUnavailableHandler(info: [AnyHashable: Any]) {
        guard
            let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
        else {
            print("could not detect previous route configuration")
            onRouteChange()
            return
        }
        print("previous route = ", previousRoute)
        onRouteChange()
        return
    }
}
