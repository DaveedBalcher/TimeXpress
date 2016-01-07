//
//  ListeningBuffer.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/20/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import Foundation

class ListeningBuffer {
    var buffer = [Double]()
    
    private let bufferSize = 10
    
    func addTap(tapTime: Double?) {
        if buffer.count >= bufferSize {
            buffer.removeLast()
        }
        if let interval = tapTime {
            buffer.insert(interval, atIndex: 0)
        } else {
            buffer = []
        }
    }
}
