//
//  Playback.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/20/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Foundation
import AVFoundation

class Playback {

    //Import Audio files
    private let audioPath1 = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("HighClick", ofType: "aiff")!)
    private let audioPath2 = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("LowClick", ofType: "aiff")!)
    
    //Initalize Audio Players
    private var downbeatClick = AVAudioPlayer()
    private var clickTwo = AVAudioPlayer()
    private var clickThree = AVAudioPlayer()
    private var clickFour = AVAudioPlayer()
    
    init() {
        setUpAudio(&downbeatClick, audioPath: audioPath1)
        setUpAudio(&clickTwo, audioPath: audioPath2)
        setUpAudio(&clickThree, audioPath: audioPath2)
        setUpAudio(&clickFour, audioPath: audioPath2)
//        keepAudioPrepared()
    }
    
    private func setUpAudio(inout audio: AVAudioPlayer, audioPath: NSURL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            try audio = AVAudioPlayer(contentsOfURL: audioPath)
            audio.prepareToPlay()
        } catch {
            print("\(audio) failed to load")
        }
    }
    
//    private let audioQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
    private var counter = 0
    
    
    //Determines if the sound that plays back should be downbeat sound
    func playClick(downbeat: Bool) {
        if downbeat {
            play(&downbeatClick)
        } else {
            switch (counter) {
            case 0:
                play(&clickTwo)
            case 1:
                play(&clickThree)
            case 2:
                play(&clickFour)
            default:
                print("error in beat counter")
            }
            if counter >= 2 {
                counter = 0
            } else {
                counter++
            }
        }
    }

    private var previousPlayer: AVAudioPlayer? = nil
    
    private func play(inout currentPlayer: AVAudioPlayer) {
        if let previous = previousPlayer {
            previous.stop()
            previous.currentTime = 0
        }
        currentPlayer.play()
        previousPlayer = currentPlayer
    }
    
//    private func play(inout currentPlayer: AVAudioPlayer) {
////        if currentPlayer.playing {
////            currentPlayer.stop()
////        }
////        currentPlayer.currentTime = 0
//        currentPlayer.play()
//    }

    
//    private func keepAudioPrepared() {
//        let waitQueue = dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
//        dispatch_async(waitQueue) { _ in
//            while true {
//                self.downbeatClick.prepareToPlay()
//                self.clickTwo.prepareToPlay()
//                self.clickThree.prepareToPlay()
//                self.clickFour.prepareToPlay()
//                usleep(5000)
//            }
//        }
//    }
    
}
