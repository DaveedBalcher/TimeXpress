//
//  MetronomeTimer.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/27/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Foundation

protocol MetronomeTimerDelegate {
    func timerTriggered(beatCount: Int)
}

class MetronomeTimer {
    
    var delegatePass : MetronomeTimerDelegate?
    
    var isNotMuted = true
    var accenting: Bool = true
    
    private let time = Time()
    private let pb = Playback()
    private let audioQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
    
    private var beatCounter = 1
    private var timeSignature: (beatsPerMeasure: Int, noteDuration: Int) = (4,4)
    private var ms: Double = 0.0
    private var previousBpm = 0.0
    
    func startTimer(bpm: Double, givenTimeSignature: (beatsPerMeasure: Int, noteDuration: Int)) {
        shouldBeActive = true
        beatCounter = 1
        previousBpm = bpm
        timeSignature = givenTimeSignature
        ms = (60000.0 * 4.0) / (bpm * Double(timeSignature.noteDuration))
        if isNotMuted {
            pb.playClick(accenting)
        }
        beatCounter++
        timerWithMachTime()
    }
    
    
    private var shouldBeActive = true
    
    func stopTimer() {
        shouldBeActive = false
    }
    
    func resetTimer(bpm: Double, givenTimeSignature: (beatsPerMeasure: Int, noteDuration: Int)) {
        timeSignature = givenTimeSignature
        ms = (60000.0 * 4.0) / (bpm * Double(timeSignature.noteDuration))
    }
    
    func resetTimer(givenTimeSignature: (beatsPerMeasure: Int, noteDuration: Int)) {
        timeSignature = givenTimeSignature
        ms = (60000.0 * 4.0) / (previousBpm * Double(timeSignature.noteDuration))
    }
    
    private var tempoCorrectionOffset = 0.33333333
    
    private func timerWithMachTime()  {
        pb.playClick(self.accenting)
        var timeWas: Double = time.getCurrentTimeInMS()
        //        let beatDivision: UInt32 = UInt32( ms / time.getMachTimeBase())
        while (shouldBeActive) {
            if ((time.getCurrentTimeInMS() - timeWas) > (ms/time.getMachTimeBase()) + tempoCorrectionOffset) {
                self.delegatePass?.timerTriggered(beatCounter++)
//                dispatch_async(audioQueue, {
//                    var accent = false
//                    if self.accenting {
//                        if self.beatCounter++ % self.timeSignature.beatsPerMeasure == 1 {
//                            accent = true
//                            dispatch_async(dispatch_get_main_queue(), { _ in
//                                self.animation(self.ms)
//                            })
//                        } else {
//                            accent = false
//                        }
//                    }
//                    if self.isNotMuted {
//                        //                        print("before \(self.time.getCurrentTimeInMS())")
//                        self.pb.playClick(accent)
//                        //                        print("after \(self.time.getCurrentTimeInMS())")
//                    }
//                })
                timeWas = time.getCurrentTimeInMS()
            }
            usleep(450)
        }
    }
    
    
    var count = 0
    
    var lastTime: UInt64 = 0
    
    //    private func timerWithMachTime()  {
    //
    ////        for var offset = 5.5; offset < 10.0; offset += 0.5 {
    //            count = 0
    ////            print(offset)
    ////            tempoCorrectionOffset = offset
    //
    //        pb.playClick(self.accenting)
    //        while (shouldBeActive) {
    //            let msToNanoSec = 1000000.0
    //            let now = mach_absolute_time()
    //            let timeToWait = UInt64(msToNanoSec * (ms - 6.3) / time.getMachTimeBase())
    //            mach_wait_until(UInt64(now + timeToWait))
    //            print(600000.0 / (time.getMachTimeBase() * Double(now - lastTime) / msToNanoSec))
    //            dispatch_async(audioQueue, {
    //                var accent = false
    //                if self.accenting {
    //                    if self.beatCounter++ % self.timeSignature.beatsPerMeasure == 1 {
    //                        accent = true
    //                        dispatch_async(dispatch_get_main_queue(), { _ in
    //                            self.animation(self.ms)
    //                        })
    //                    } else {
    //                        accent = false
    //                    }
    //                }
    //                if self.isNotMuted {
    //                    self.pb.playClick(accent)
    //                    self.lastTime = now
    //                    self.count++
    //                }
    //            })
    //        }
    ////        }
    //    }
    
    //    private func timerWithNSDate() {
    //        var timeWas: Double = NSDate.timeIntervalSinceReferenceDate()
    //        while (shouldBeActive) {
    //            if ((NSDate.timeIntervalSinceReferenceDate() - timeWas) > ms/1000) {
    //                dispatch_async(audioQueue, {
    //                    var accent = false
    //                    if self.accenting {
    //                        if self.beatCounter++ % self.timeSignature.beatsPerMeasure == 1 {
    //                            accent = true
    //                            dispatch_async(dispatch_get_main_queue(), { _ in
    //                                self.animation(self.ms)
    //                            })
    //                        } else {
    //                            accent = false
    //                        }
    //                    }
    //                    if self.isNotMuted {
    //                        self.pb.playClick(accent)
    //                    }
    //                })
    //                timeWas = NSDate.timeIntervalSinceReferenceDate()
    //            }
    //            usleep(500)
    //        }
    //    }
    //


    
//    private func timerWithMachTime() {
//        var timeWas: Double = time.getCurrentTimeInMS()
//        while (shouldBeActive) {
//            if ((time.getCurrentTimeInMS() - timeWas) > ms) {
//                dispatch_async(audioQueue, {
//                    var accent = false
//                    if self.accenting {
//                        accent = (self.beatCounter++ % self.timeSignature.beatsPerMeasure == 1) ? true : false
//                    }
//                    if self.isNotMuted {
//                        self.pb.playClick(accent)
//                    }
//                })
//                timeWas = time.getCurrentTimeInMS()
//            }
//            usleep(500)
//        }
//    }

//    private func timerWithNSDate(ms:Double) {
//        let seconds = ms/1000
//        var timeWas: Double = NSDate.timeIntervalSinceReferenceDate()
//        while (shouldBeActive) {
//            if ((NSDate.timeIntervalSinceReferenceDate() - timeWas) > seconds) {
//                dispatch_async(audioQueue, {
//                    var accent = false
//                    if self.accenting {
//                        accent = (self.beatCounter++ % self.timeSignature.beatsPerMeasure == 1) ? true : false
//                    }
//                    if self.isNotMuted {
//                        self.pb.playClick(accent)
//                    }
//                })
//                timeWas = NSDate.timeIntervalSinceReferenceDate()
//            }
//            usleep(500)
//        }
//    }
}
