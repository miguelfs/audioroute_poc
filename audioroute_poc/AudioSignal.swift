import AVFoundation

enum Waveform {
    case silence, senoid, majorThird, completion
}

typealias Duration = Measurement<UnitDuration>
typealias Offset = Measurement<UnitDuration>

struct TimeUnit {
    static func samples(with sampleRate:  Double) -> UnitDuration {
        return UnitDuration(symbol: "samples", converter: UnitConverterLinear(coefficient: 1/sampleRate))
    }
    
    static func asSamples(_ duration: Duration, with sampleRate: Double) -> Int {
        return Int(duration.converted(to: samples(with: sampleRate)).value)
    }
}

struct AudioSignal {
    var sampleRate: Double = 48000
    var sampleSize: Int = 8
    var waveform: Waveform
    var amplitude: Float
    var frequency: Float
    var startOffset: Offset
    var soundDuration: Duration
    var duration: Duration

    init(sampleRate: Double = 48000, waveform: Waveform = .senoid, frequency: Float = 880,
         startOffset: Double = 0, soundDuration: Double = 1) {
        self.sampleRate = sampleRate
        self.waveform = waveform
        self.frequency = frequency
        self.startOffset = Offset(value: startOffset, unit: .seconds)
        self.soundDuration = Duration(value: soundDuration, unit: .seconds)
        self.duration = self.startOffset + self.soundDuration
        self.amplitude = Float(truncating: NSDecimalNumber(decimal: pow(2, sampleSize - 1))) - 1.0
    }

    private func getAsData() -> Data {
        assert(soundDuration.unit == .seconds)
        var data = Data(count: TimeUnit.asSamples(soundDuration, with: sampleRate))
        switch waveform {
        case .senoid:
            for index in 0..<data.count {
                let tone = UInt8(amplitude * (1 + sin(2 * .pi * Float(index) * frequency / Float(sampleRate)))/2)
                data[index] = tone
            }
        case .majorThird:
            for index in 0..<data.count {
                let phase = 2 * .pi * Float(index) * frequency
                let tone = UInt8(amplitude * (1 + sin(phase / Float(sampleRate)))/4)
                let third = UInt8(amplitude * (1.0 + sin(phase * (5/4) / Float(sampleRate)))/4)
                data[index] = tone + third
            }
        case .completion:
            for index in 0..<data.count/8 {
                let phase = 2 * .pi * Float(index) * frequency
                let tone = UInt8(amplitude * (1 + sin(phase / Float(sampleRate)))/4)
                let second = UInt8(amplitude * (1.0 + sin(phase * (9/8) / Float(sampleRate)))/4)
                let third = UInt8(amplitude * (1.0 + sin(phase * (5/4) / Float(sampleRate)))/4)
                let forth = UInt8(amplitude * (1.0 + sin(phase * (4/3) / Float(sampleRate)))/4)
                let octave = UInt8(amplitude * (1.0 + sin(phase * (2) / Float(sampleRate)))/4)
                data[index] = tone
                data[data.count/8 + index] = second
                data[data.count/4 + index] = third
                data[3*data.count/8 + index] = forth
                data[data.count/2 + index] = forth
                data[5*data.count/8 + index] = octave
                data[3*data.count/4 + index] = octave
                data[7*data.count/8 + index] = forth
            }
        default: ()
        }
        if startOffset.value > 0 {
            var offset = Data(count: TimeUnit.asSamples(startOffset, with: sampleRate))
            offset.append(data)
            data = offset
        }
        return data
    }

    func getAsPCMBuffer(audioFormat: AVAudioFormat) -> AVAudioPCMBuffer {
        let data = getAsData()
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(data.count))
        audioBuffer!.frameLength = audioBuffer!.frameCapacity
        switch waveform {
        case .silence:
            for index in 0..<data.count {
                audioBuffer?.floatChannelData?.pointee[index] =
                    Float(Int16(data[index]) << 8 | Int16(data[index]))/Float(INT16_MAX)
            }
        default:
            let offsetLength = TimeUnit.asSamples(startOffset, with: sampleRate)
            for index in 0..<Int(offsetLength) {
                audioBuffer?.floatChannelData?.pointee[index] =
                    Float(Int16(data[index]) << 8 | Int16(data[index]))/Float(INT16_MAX)
            }
            for index in Int(offsetLength)..<data.count {
                let value = Float(Int16(data[index]) << 8 | Int16(data[index]))/Float(INT16_MAX) - 0.5
                audioBuffer?.floatChannelData?.pointee[index] = value
            }
        }
        return audioBuffer!
    }

    private func renderToFile(_ file: AVAudioFile) {
        try? file.write(from: getAsPCMBuffer(audioFormat: file.processingFormat))
    }

    func generateFile() -> (String, URL) {
        let filename = "signal_offset_\(startOffset)_duration_\(duration)_freq_\(frequency).aiff"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: url)

        let settings: [String: Any] = [AVSampleRateKey: sampleRate, AVNumberOfChannelsKey: 1]

        let file = try? AVAudioFile(forWriting: url, settings: settings)
        renderToFile(file!)

        return (filename, url)
    }
}
