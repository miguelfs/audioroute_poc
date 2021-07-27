import AVFoundation

public typealias RouteOptions = (_ routeDescription: AVAudioSessionRouteDescription) -> Bool

class AudioRoute {
    func currentOutputIsBluetooth() -> Bool {
        let session = AVAudioSession.sharedInstance()
        guard let output = session.currentRoute.outputs.first else {
            return false
        }
        return [.bluetoothA2DP, .bluetoothLE, .bluetoothHFP].contains(output.portType)
    }
    
    func getCurrentOutput() -> String {
        let session = AVAudioSession.sharedInstance()
        guard let output = session.currentRoute.outputs.first else {
            return ""
        }
        return output.portName
    }
    
    func getCurrentInput() -> String {
        let session = AVAudioSession.sharedInstance()
        guard let input = session.currentRoute.inputs.first else {
            return ""
        }
        return input.portName
    }
    
    func setInput(portName: String) {
        let session = AVAudioSession.sharedInstance()
        guard let availableInputs = session.availableInputs,
              let micInput = availableInputs.first(where: { $0.portName == portName}) else {
            print("input device \(portName) not found")
            return
        }
        setInput(portDescription: micInput)
    }
    
    func setInput(portType: AVAudioSession.Port) {
        let session = AVAudioSession.sharedInstance()
        guard let availableInputs = session.availableInputs,
              let micInput = availableInputs.first(where: { $0.portType == portType}) else {
            print("input device \(portType) not found")
            return
        }
        setInput(portDescription: micInput)
    }
    
    func setInput(portDescription micInput: AVAudioSessionPortDescription) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setPreferredInput(micInput)
        } catch {
            print("Unable to set \(micInput) as preferred input")
        }
    }
    
    func getAvailableInputs() -> [String] {
        let session = AVAudioSession.sharedInstance()
        var arr = [String]()
        if let inputs = session.availableInputs {
            for input in inputs {
                arr.append(input.portName)
            }
        }
        return arr
    }
    
    func hasHeadPhones() -> RouteOptions {
        return { (routeDescription: AVAudioSessionRouteDescription) -> Bool in
            return !routeDescription.outputs.filter({$0.portType == .headphones}).isEmpty
        }
    }
    
    func hasBluetooth() -> RouteOptions {
        return { (routeDescription: AVAudioSessionRouteDescription) -> Bool in
            return !routeDescription.outputs.filter({$0.portType == .bluetoothLE}).isEmpty ||
                !routeDescription.outputs.filter({$0.portType == .bluetoothHFP}).isEmpty ||
                !routeDescription.outputs.filter({$0.portType == .bluetoothA2DP}).isEmpty
        }
    }
    
    func hasSpeakerBuiltIn() -> RouteOptions {
        return { (routeDescription: AVAudioSessionRouteDescription) -> Bool in
            return !routeDescription.outputs.filter({$0.portType == .builtInSpeaker}).isEmpty
        }
    }
}

public func checkOutput(in routeDescription: AVAudioSessionRouteDescription, verifiers: [RouteOptions]) -> Bool {
    let hasDescribedOutput = verifiers.filter {
        $0(routeDescription)
    }
    return hasDescribedOutput.count > 0
}

