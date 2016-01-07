//
//  Tap.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/20/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Darwin

class Tap: Time {
    let time = Time()
    var count = 0

    // 40 bpm = 1.5 second interval
    private var slowest = 1.5
    
    // 500 bpm = .12 second interval
    private var fastest = 0.12
    
    private var previousTimestamp: Double? = nil
    
    func getInterval(currentTimestamp: Double) -> Double? {
        var interval: Double? = nil
        if let previous = previousTimestamp {
            interval = currentTimestamp - previous
            if interval > slowest || interval < fastest {
                interval = nil
            }
        }
        previousTimestamp = currentTimestamp
        
        return interval
    }
}



//
//    func getTapStamp() -> (Int, Double?) {
//        var interval: Double?
//        let intervalInMS = time.getTimeIntervalInMS()
//        if intervalInMS > slowest || intervalInMS < fastest {
//            interval = nil
//        } else {
//            interval = intervalInMS
//        }
//        return (++count, interval)
//    }