import AVFoundation

typealias InterruptionAction = (Notification) -> Void
typealias Handler = (AudioCore) -> InterruptionAction
 
func handleMediaOsReset(control: AudioCore) -> InterruptionAction {
    return { (_) in
        print("handleMediaOsReset")
    }
}
 
func handleMediaOsLost(control: AudioCore) -> InterruptionAction {
    return { (_) in
        print("handleMediaOsLost")
    }
}
 
func handleNotificationInterruption(control: AudioCore) -> InterruptionAction {
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
            recordingInterruptionHandler(control: control)
            playInterruptionBeganHandler(control: control)
        case .ended:
            print("interruption ended")
            // there is no handle to recording. Once is settle to not interrupt,
            // otherwise if is not available on version, it will stop recording
            // on began and does nothing on ended
            playInterruptionEndedHandler(control: control)
        default:
            return
        }
    }
}

private func playInterruptionBeganHandler(control: AudioCore) {
        print("pausing audioEngine due to interruption")
        control.pause()
}

private func playInterruptionEndedHandler(control: AudioCore) {
    print("play interruption ended handler")
}

private func recordingInterruptionHandler(control: AudioCore) {
    print("recording interruption handler")
}

func handleOnRouteChange(control: AudioCore) -> InterruptionAction {
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
            newDeviceAvailableHandler(control: control)
        case .oldDeviceUnavailable:
            print("handleOnRouteChange: old device available")
            oldDeviceUnavailableHandler(control: control, info: info)
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

private func newDeviceAvailableHandler(control AudioCore: AudioCore) {
    print("headphone or bluetooth detected...")
    return
}

private func oldDeviceUnavailableHandler(control AudioCore: AudioCore, info: [AnyHashable: Any]) {
    guard
        let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
    else {
        print("could not detect previous route configuration")
        return
    }
    print("previous route = ", previousRoute)
    return
}
