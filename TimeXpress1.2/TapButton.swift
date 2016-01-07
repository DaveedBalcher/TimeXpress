//
//  TapButton.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 11/3/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import UIKit

protocol TapButtonDelegate {
    func touchBegan(timestamp: Double)
//    func touchMoved()
    func shortTouchEnded()
    func longTouchEnded()
    func noTouchInEightSec()
}

class TapButton: UIButton {
    
    private var currentTimestamp = 0.0
    
    var delegatePass : TapButtonDelegate?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch =  touches.first {
            currentTimestamp = touch.timestamp
            
            // Notify it's delegate about touched
            self.delegatePass?.touchBegan(currentTimestamp)
        }
        
        super.touchesBegan(touches, withEvent: event)
    }
    
    
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let endTouchTime: Double
        if let endTouch =  touches.first {
            endTouchTime = endTouch.timestamp
            if endTouchTime - currentTimestamp > 1.0 {
                self.delegatePass?.longTouchEnded()
            } else {
                self.delegatePass?.shortTouchEnded()
            }
        }
        
        let waitQueue = dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
        let time: Int64 = Int64(8 * NSEC_PER_SEC)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), waitQueue) { _ in
            self.delegatePass?.noTouchInEightSec()
        }
        
        super.touchesEnded(touches, withEvent: event)
    }
    
    
//    func blinkButton() {
//        if self.alpha == 1.0 {
//            self.alpha = 0.6
//        } else {
//            self.alpha = 1.0
//        }
//    }
//    
//    func normalizeButton() {
//        self.alpha = 1.0
//    }
    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        
//        self.delegatePass?.touchMoved()
//        
//        if let touch = touches.first{
//            print("\(touch)")
//        }
//        super.touchesMoved(touches, withEvent: event)
//    }
    

}