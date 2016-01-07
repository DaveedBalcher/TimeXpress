//
//  MicrophoneListener.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 12/1/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Foundation
import Accelerate
import AVFoundation

protocol MicrophoneListenerDelegate {
    func touchBegan(timestamp: Double)
}

class MicrophoneListener {
    
    var audioEngine: AVAudioEngine!
    var delegatePass : MicrophoneListenerDelegate?
    let time = Time()
    let micListeningQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
    
    
    func startListener() {
        dispatch_async(micListeningQueue, { _ in
            self.audioEngine = AVAudioEngine()
            
            //Audio Input
            let inputNode = self.audioEngine.inputNode
            let sampleCount = 2048
            let frameLength = UInt32(sampleCount)
            let mainBus = 0
            var tapSamples = Array(count: Int(sampleCount), repeatedValue: CDouble())
            
            var previousTapFFT: [Double]! = nil
            let bufferSize = 100
            var fftEnergies: [Double] = []
            var summedDiffFFT = 0.0
            var sdEnergy = 0.0
            var avgEnergy = 0.0
            var energyThreshold = 0.0
            
            inputNode!.installTapOnBus(mainBus,
                bufferSize:frameLength,
                format: inputNode!.inputFormatForBus(mainBus),
                block: {(
                    buffer: AVAudioPCMBuffer!,
                    audioTime  : AVAudioTime!) in
                    
                    // Change incomming buffer size
                    buffer.frameLength = frameLength
                    
                    // Populate array with incomming audio samples
                    for var i = 0; i < Int(buffer.frameLength); i++ {
                        tapSamples[i] = Double(buffer.floatChannelData.memory[i])
                    }
                    
                    // Get Energy with FFT
                    let tapFFT = fft(tapSamples)
                    
                    // Take Difference of Magnitude Spectra
                    var diffFFT = [Double]()
                    if (previousTapFFT != nil) {
                        diffFFT = tapFFT - previousTapFFT
                        summedDiffFFT = sum(diffFFT)
                        fftEnergies.append(summedDiffFFT)
                    }
                    previousTapFFT = tapFFT
                    //                print(summedDiffFFT)
                    
                    // Populate Energy Buffer
                    if fftEnergies.count >= bufferSize {
                        
                        //Take Standard Deviation
                        if let result = standardDeviationSample(fftEnergies) {
                            sdEnergy = result
                        }
                        if let result = average(fftEnergies) {
                            avgEnergy = result
                        }
                        
                        energyThreshold = (sdEnergy * 3) + avgEnergy
                        
                        //Reset Energies Buffer
                        fftEnergies = []
                    }
                    
                    if summedDiffFFT > energyThreshold {
                        let timestamp = self.time.getCurrentTimeInMS() * 0.001
                        self.delegatePass?.touchBegan(timestamp)
                        
                        //                    print("\(summedDiffFFT) > \(energyThreshold)")
                    }
                    
                })
            
                self.audioEngine.prepare()
                do {
                    try self.audioEngine.start()
                } catch _ {
                }
            })

        }
    
    func stopListener() {
        audioEngine.stop()
    }
}

// MARK: - FFT

public func fft(input: [Double]) -> [Double] {
    var real = [Double](input)
    var imaginary = [Double](count: input.count, repeatedValue: 0.0)
    var splitComplex = DSPDoubleSplitComplex(realp: &real, imagp: &imaginary)
    
    let length = vDSP_Length(floor(log2(Float(input.count))))
    let radix = FFTRadix(kFFTRadix2)
    let weights = vDSP_create_fftsetupD(length, radix)
    vDSP_fft_zipD(weights, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
    
    var magnitudes = [Double](count: input.count, repeatedValue: 0.0)
    vDSP_zvmagsD(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
    
    var normalizedMagnitudes = [Double](count: input.count, repeatedValue: 0.0)
    for var index = 0; index < magnitudes.count; index++ {
        magnitudes[index] = sqrt(magnitudes[index])
    }
    vDSP_vsmulD(magnitudes, 1, [2.0 / Double(input.count)], &normalizedMagnitudes, 1, vDSP_Length(input.count))
    
    vDSP_destroy_fftsetupD(weights)
    
    return log10(magnitudes)
}

public func log10(x: [Double]) -> [Double] {
    var results = [Double](count: x.count, repeatedValue: 0.0)
    vvlog10(&results, x, [Int32(x.count)])
    
    return results
}


// MARK: - Operators

public func sub(x: [Double], y: [Double]) -> [Double] {
    var results = [Double](y)
    cblas_daxpy( -1 * Int32(x.count), 1.0, x, 1, &results, 1)
    
    return results
}

public func - (lhs: [Double], rhs: [Double]) -> [Double] {
    return sub(lhs, y: rhs)
}

public func - (lhs: [Double], rhs: Double) -> [Double] {
    return sub(lhs, y: [Double](count: lhs.count, repeatedValue: rhs))
}


// MARK: Sum

public func sum(x: [Double]) -> Double {
    var result: Double = 0.0
    vDSP_sveD(x, 1, &result, vDSP_Length(x.count))
    
    return result
}


// MARK: Standard Deviation

public func average(values: [Double]) -> Double? {
    let count = Double(values.count)
    if count == 0 { return nil }
    return sum(values) / count
}


public func varianceSample(values: [Double]) -> Double? {
    let count = Double(values.count)
    if count < 2 { return nil }
    
    if let avgerageValue = average(values) {
        let numerator = values.reduce(0) { total, value in
            total + pow(avgerageValue - value, 2)
        }
        
        return numerator / (count - 1)
    }
    
    return nil
}

public func standardDeviationSample(values: [Double]) -> Double? {
    if let varianceSample = varianceSample(values) {
        return sqrt(varianceSample)
    }
    
    return nil
}


