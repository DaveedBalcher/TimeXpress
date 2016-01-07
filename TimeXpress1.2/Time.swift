//
//  Time.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/27/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Darwin

class Time {
    private static var base: Double = 0
    private var previousTime: UInt64 = 0
    private var currentTime: UInt64 = 0
    
    init() {
        if Time.base == 0 {
            var info = mach_timebase_info(numer: 0, denom: 0)
            mach_timebase_info(&info)
            Time.base = Double(info.numer) / Double(info.denom)
        }
    }
    
    private func getCurrentTime() {
        currentTime = mach_absolute_time()
    }
    
    func getCurrentTimeInMS() -> Double {
        getCurrentTime()
        return Double(currentTime) / 1_000_000
    }
    
    // in nanoseconds
    private var intInterval: UInt64 {
        return currentTime - previousTime
    }
    
    private var intervalInMS: Double {
        return Double(intInterval) * Time.base / 1_000_000
    }
    
    func getMachTimeBase() -> Double {
        return Double(Time.base)
    }
}


//    func getTimeIntervalInMS() -> Double {
//        getCurrentTime()
//        let interval = intervalInMS
//        previousTime = currentTime
//        return interval
//    }
