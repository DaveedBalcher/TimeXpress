//
//  BpmCalculator.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/20/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Foundation

class BpmCalculator {
    var bpm: Double? = 120.0
//    enum userIntensionState {
//        case tappingConsistently, couldBeSettingNewTempo, settingNewTempo, tappingRandomly
//    }
    
    private var bpmHistory = [Double]()
//    private var previousUserIntensionState = userIntensionState.tappingConsistently
//    
    
    func calculateBpm(bufferOfTimeIntervals: [Double]) {
        bpmsFromIntervals(bufferOfTimeIntervals)
        interpretBpmBuffer()
        bpm = calcAverageBpm()
    }
    
    
    private let millisecondsInMinute = 60000.0
    
    private let secondsInMinute = 60.0
    
    private func bpmsFromIntervals(intervals: [Double]) {
        bpmHistory.removeAll()
        for interval in intervals {
            bpmHistory.append(secondsInMinute / interval)
        }
    }
    
    // Interpretation Buffer Size
    private let interpSize = 6
    private let consistencyPercentage = 7.0
    
    private var tempoGroups: [Int] = []
    private var tempoGroupValues: [[Double]] = [[]]
    
    private func interpretBpmBuffer() {
        var interpBuffer: [Double] = []
        for bpmValue in bpmHistory {
            interpBuffer.append(bpmValue)
            if interpBuffer.count >= interpSize {
                break
            }
        }
        
        //Add First Element
        tempoGroups = [1]
        tempoGroupValues = [[interpBuffer[0]]]

        let adjustedConsistencyPercentage = tempoVarianceAdjustment(average(interpBuffer)) * consistencyPercentage
        
        //Separate into tempo groups
        var groupNumber = 0
        while interpBuffer.count >= 2 {
            let firstBpm = interpBuffer.removeFirst()
            let secondBpm = interpBuffer.first!
            if percentChange(firstBpm, element2: secondBpm) < adjustedConsistencyPercentage {
                tempoGroups[groupNumber] += 1
            } else {
                groupNumber++
                tempoGroups.append(1)
                tempoGroupValues.append([])
            }
            tempoGroupValues[groupNumber].append(secondBpm)
        }

        print(tempoGroups)
//        print(tempoGroupValues)
        
        //Add only connsistent tempo groups back into bpmHistory
        var newBpmHistory: [Double] = []
        if tempoGroupValues[0].count == 1 {
            newBpmHistory = tempoGroupValues[0]
        } else {
            for (index, groupValues) in tempoGroupValues.enumerate() {
                if groupValues.count > 1 {
                    for value in tempoGroupValues[index] {
                        newBpmHistory.append(value)
                    }
                }
            }
            if newBpmHistory == [] {
                newBpmHistory.append(bpmHistory[0])
            } else {
                //Check that two groups have low devience in tempo
                let firstGroup = Array(newBpmHistory[0..<tempoGroups[0]])
                let secondGroup = Array(newBpmHistory[tempoGroups[0]..<newBpmHistory.count])
                let adjustedConsistencyPercentage = tempoVarianceAdjustment(average(bpmHistory)) * 18.0
                if percentChange(firstGroup[0], element2: average(secondGroup)) > adjustedConsistencyPercentage {
                    newBpmHistory = firstGroup
                }
            }
        }
                bpmHistory = newBpmHistory
    }
    
    private func calcAverageBpm() -> Double {
        var totalTempos = 0.0
        var totalStrength = 0.0
        
        for (index, bpm) in bpmHistory.enumerate() {
            let strength = pow(Double(bpmHistory.count - index), 1.2)
            totalTempos += bpm * strength
            totalStrength += strength
        }
        return totalTempos / totalStrength
    }
    
    private func average(arr: [Double]) -> Double {
        let length = Double(arr.count)
        return arr.reduce(0, combine: {$0 + $1}) / length
    }

    private func percentChange(element1: Double, element2: Double) -> Double {
        if element2 >= element1 {
            return (element2 - element1) / element2 * 100
        } else {
            return (element1 - element2) / element1 * 100
        }
    }
    
    private func tempoVarianceAdjustment(tempo: Double) -> Double {
        var adjustment = ((7 / 900) * tempo + 0.7)
        if adjustment > 2.8 {
        adjustment = 2.8
        }
        return adjustment
    }
    
}



// Previous Versions of Methods


//func calculateBpm(bufferOfTimeIntervals: [Double]) {
//    bpmsFromIntervals(bufferOfTimeIntervals)
//    interpretBpmBuffer()
//    switch (currentUserIntensionState) {
//    case userIntensionState.tappingConsistently:
//        bpm = calcAverageBpm()
//    case userIntensionState.couldBeSettingNewTempo:
//        if previousUserIntensionState == userIntensionState.tappingRandomly{
//            break
//        } else {
//            fallthrough
//        }
//    case userIntensionState.settingNewTempo:
//        excludeExtremeOutliers()
//        bpm = calcAverageBpm()
//    case userIntensionState.tappingRandomly:
//        bpm = nil
//    }
//}


//private func interpretBpmBuffer() {
//    previousUserIntensionState = currentUserIntensionState
//    
//    var interpBuffer: [Double] = []
//    for bpmValue in bpmHistory {
//        interpBuffer.append(bpmValue)
//        if interpBuffer.count > interpSize {
//            break
//        }
//    }
//    
//    tempoGroups = [1]
//    
//    let adjustedConsistencyPercentage = tempoVarianceAdjustment(average(interpBuffer)) * consistencyPercentage
//    
//    var groupNumber = 0
//    while interpBuffer.count >= 2 {
//        let firstBpm = interpBuffer.removeFirst()
//        let secondBpm = interpBuffer.first!
//        if percentChange(firstBpm, element2: secondBpm) < adjustedConsistencyPercentage {
//            tempoGroups[groupNumber] += 1
//        } else {
//            groupNumber++
//            tempoGroups.append(1)
//        }
//    }
//    
//    print(tempoGroups)
//    let numberOfTempoGroups = tempoGroups.count
//    
//    switch (numberOfTempoGroups) {
//    case 1:
//        currentUserIntensionState = userIntensionState.tappingConsistently
//    case 2:
//        if tempoGroups[0] <= 1 {
//            currentUserIntensionState = userIntensionState.couldBeSettingNewTempo
//        } else {
//            currentUserIntensionState = userIntensionState.settingNewTempo
//        }
//    case 3:
//        var count = 0
//        for groupValue in tempoGroups {
//            if groupValue == 1 { count++ }
//        }
//        if count > 1 {
//            currentUserIntensionState = userIntensionState.couldBeSettingNewTempo
//        } else {
//            fallthrough
//        }
//    case 3..<bpmHistory.count:
//        currentUserIntensionState = userIntensionState.tappingRandomly
//    default:
//        print("Error: undeffinity amount of tempo groups \(numberOfTempoGroups)")
//    }
//}


//    private func excludeExtremeOutliers() {
//        var oldBpmHistory: [Double] = bpmHistory
//        var newBpmHistory: [Double] = []
//        for var bpmIndex = 0; bpmIndex < tempoGroups[0]; bpmIndex++ {
//            newBpmHistory.append(oldBpmHistory.removeFirst())
//        }
//        let newTempoAverage = average(newBpmHistory)
//        let adjustedConsistencyPercentage = tempoVarianceAdjustment(newTempoAverage) * consistencyPercentage
//        for var bpmIndex = oldBpmHistory.count - 1; bpmIndex >= tempoGroups[0] ; bpmIndex-- {
//            if percentChange(bpmHistory[bpmIndex], element2: newTempoAverage) > adjustedConsistencyPercentage {
//                bpmHistory.removeAtIndex(bpmIndex)
//            }
//        }
//    }


