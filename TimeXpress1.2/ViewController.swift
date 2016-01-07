//
//  ViewController.swift
//  TimeXpress1.2
//
//  Created by David Balcher on 10/20/15.
//  Copyright © 2015 David Balcher. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, TapButtonDelegate, MicrophoneListenerDelegate {

    @IBOutlet weak var tapTempoButton: TapButton!
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var imageAnimationView: UIImageView!
    @IBOutlet weak var playButton: UIButton!

    @IBOutlet weak var beatAccentLabel: UILabel!
    @IBOutlet weak var noteDurationImageView: UIImageView!
    @IBOutlet weak var timeSignatureView: UIView!
    @IBOutlet weak var timeSignaturePicker: UIPickerView!
    
    
    // Varibles metronome playback
    var imgListArray: [UIImage] = []
    
    let tp = Tap()
    let listener = ListeningBuffer()
    let calc = BpmCalculator()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTimeSignaturePickerView()
        loadImages()
 
        tapTempoButton.delegatePass = self
        ml.delegatePass = self
        
        //        gestureSetup()
    }
    
    // Marker: Set up functions

    //Loads images for background animation
    func loadImages() {
        for index in 1...9 {
            imgListArray += [UIImage(named: "BeatAnimation_\(index).png")!]
        }
        imageAnimationView.animationImages = imgListArray
        imageAnimationView.animationRepeatCount = 1
        imageAnimationView.animationDuration = 0.5
    }
    
    func setUpTimeSignaturePickerView() {
        timeSignatureView.hidden = true
        timeSignaturePicker.selectRow(3, inComponent: 0, animated: false)
        timeSignaturePicker.selectRow(0, inComponent: 1, animated: false)
    }
    
    // Marker: Metronome Functions (Play, Pause, Mute)
    
    var waitingToReset = false
    
    let touchAudioQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
    
    func touchBegan(timestamp: Double) {
        print(timestamp)
        if (!metronomeIsPlaying || waitingToReset) {
            dispatch_async(touchAudioQueue, { _ in
                self.pb.playClick(false)
            })
//        } else if (metronomeIsPlaying && !waitingToReset) {
//            playPause(playButton)
        }
        if let interval = tp.getInterval(timestamp) {
            listener.addTap(interval)
            calc.calculateBpm(listener.buffer)
            print(calc.bpm)
            dispatch_async(dispatch_get_main_queue(), { _ in
            if let bpm = self.calc.bpm{
                self.tempoLabel.text = "\(Int(bpm))"
            } else {
                self.tempoLabel.text = "---"
            }
            })
        }
    }
    
    var timeSincePreviousShortTap: Double = 0.0
    var previousShortTap: Double? = nil
    
    func shortTouchEnded() {
        if (metronomeIsPlaying && !waitingToReset) {
            stopTimer()
            resetAfterTwoSeconds()
            let waitingQueue = dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.rawValue), 0)
            dispatch_async(waitingQueue, { _ in
                while self.waitingToReset {
                    usleep(500)
                }
                self.startTimer(self.calc.bpm!, givenTimeSignature: self.timeSignature)
            })
        }

    }
    
    let ml = MicrophoneListener()
    var micListenerOn = false
    
    func longTouchEnded() {
        if micListenerOn {
            ml.stopListener()
        } else {
            ml.startListener()
        }
        micListenerOn = !micListenerOn
//        playPause(playButton)
        
    }
    
    func noTouchInEightSec() {
    
    }
    
    func resetAfterTwoSeconds() {
        waitingToReset = true
        let delay = 2.4 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.waitingToReset = false
        }
    }
    
    private var metronomeIsPlaying = false {
        didSet {
            if metronomeIsPlaying {
                startTimer(calc.bpm!, givenTimeSignature: timeSignature)
            } else {
                stopTimer()
            }
        }
    }
    
    @IBAction func playPause(sender: UIButton) {
        if (calc.bpm == 0) {
            warningNoTap()
        } else {
            sender.selected = !sender.selected
//            stopTimer()
//            if(!metronomeIsPlaying){
//                playMetronome()
//            }
            metronomeIsPlaying = !metronomeIsPlaying
        }
    }
    
    func warningNoTap() {
        self.tempoLabel.hidden = false
        self.tempoLabel.text = "Tap"
    }

    func playMetronome() {
//        checkIfFastAccent()
    
            self.startTimer(self.calc.bpm!, givenTimeSignature: self.timeSignature)
    }
    
    @IBAction func muteUnmute(sender: UIButton) {
        sender.selected = !sender.selected
        isNotMuted = !isNotMuted
    }
    
    @IBAction func openPickerView() {
        timeSignatureView.hidden = false
        timeSignatureView.alpha = 0.0
        UIView.animateWithDuration(0.25) { () -> Void in
            self.timeSignatureView.alpha = 1.0
        }
        let button   = UIButton(type: UIButtonType.Custom) as UIButton
        button.frame = view.bounds
        button.alpha = 0.12
        button.backgroundColor = UIColor.blackColor()
        button.addTarget(self, action: "closePickerView:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.insertSubview(button, belowSubview: timeSignatureView)
        
    }
    
    @IBAction func closePickerView(sender: UIButton) {
        sender.removeFromSuperview()
        timeSignatureView.alpha = 1.0
        UIView.animateWithDuration(0.25, animations: { _ in
            self.timeSignatureView.alpha = 0.0
            }, completion: { _ in
                self.timeSignatureView.hidden = true
        })
    }
    
    
    // Marker: Metronome Timer
    var isNotMuted = true
    var accenting: Bool = true
    
    private let time = Time()
    private lazy var pb = Playback()
    private let playbackAudioQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
    private let clickQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
    
    private var beatCounter = 1
    private var ms: Double = 0.0 {
        didSet{
            if ms < 75 {
                playPause(playButton)
                setTimeSignatureToQuaterNotes()
                displayTooFastWarning()
            }
        }
    }
    private var previousBpm = 0.0
    
    func startTimer(bpm: Double, givenTimeSignature: (beatsPerMeasure: Int, noteDuration: Int)) {
        shouldBeActive = true
        beatCounter = 1
        previousBpm = bpm
        ms = (60000.0 * 4.0) / (round(bpm) * Double(timeSignature.noteDuration))
        dispatch_async(dispatch_get_main_queue(), { _ in
            self.animation(self.ms)
        })
        beatCounter++
        timerWithMachTime()
    }
    
    private var shouldBeActive = true
    
    func stopTimer() {
        shouldBeActive = false
    }
    
    func resetTimer(bpm: Double) {
        ms = (60000.0 * 4.0) / (bpm * Double(timeSignature.noteDuration))
    }
    
    func resetTimer() {
        ms = (60000.0 * 4.0) / (previousBpm * Double(timeSignature.noteDuration))
    }

    
    var lastTime: UInt64 = 0
    var count = 0
    let offset = 0.987
    
    private func timerWithMachTime()  {
        dispatch_async(playbackAudioQueue, {
            if self.isNotMuted {
                self.pb.playClick(self.accenting)
            }
        })
        dispatch_async(clickQueue, { _ in
            while (self.shouldBeActive) {
                let msToNanoSec = 1000000.0
                let now = mach_absolute_time()
                let timeToWait = UInt64(msToNanoSec * self.ms * self.offset / self.time.getMachTimeBase())
                mach_wait_until(UInt64(now + timeToWait))
//                print(60000.0 / (self.time.getMachTimeBase() * Double(now - self.lastTime) / msToNanoSec))
                dispatch_async(self.playbackAudioQueue, {
                    var accent = false
                    if self.accenting {
                        if self.beatCounter++ % self.timeSignature.beatsPerMeasure == 1 {
                            accent = true
                            dispatch_async(dispatch_get_main_queue(), { _ in
                                self.animation(self.ms)
                            })
                        } else {
                            accent = false
                        }
                    }
                    if self.isNotMuted {
                        self.pb.playClick(accent)
                    } else {
//                        dispatch_async(dispatch_get_main_queue(), { _ in
//                            self.tapTempoButton.blinkButton()
//                        })
                    }
                })
            }
        })
    }
    

//    private var tempoCorrectionOffset = 0.033333333
//    
//    private func timerWithMachTime()  {
//        pb.playClick(self.accenting)
//        var timeWas: Double = time.getCurrentTimeInMS()
////        let beatDivision: UInt32 = UInt32( ms / time.getMachTimeBase())
//        while (shouldBeActive) {
//            if ((time.getCurrentTimeInMS() - timeWas) > (ms/time.getMachTimeBase()) + tempoCorrectionOffset) {
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
//                timeWas = time.getCurrentTimeInMS()
//            }
//            usleep(240)
//        }
//    }

    
    func setTimeSignatureToQuaterNotes() {
        timeSignature.noteDuration = 4
        dispatch_async(dispatch_get_main_queue(), { _ in
        let quaterNoteRow = 0
        self.noteDurationImageView.image = self.noteDurationImage[quaterNoteRow]
        self.timeSignaturePicker.selectRow(quaterNoteRow, inComponent: 1, animated: true)
        self.pickerView(self.timeSignaturePicker, didSelectRow: quaterNoteRow, inComponent: 1)
        })
    }
    
    
    func displayTooFastWarning() {
        dispatch_async(dispatch_get_main_queue()) { _ in
            let alertController = UIAlertController(title: "Too Fast", message:
                "We have set your note denomination to quarter notes", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
    // Marker: Tempo Animation
    
    func animation(ms: Double) {
        imageAnimationView.animationDuration = (2.0 + (ms/1000)) / 5
        imageAnimationView.startAnimating()
    }
    
    
    // Marker: Picker View Settings
    
    // Stored Time-Signature Information
    let beatsPerMeasure = [ 1, 2, 3, 4, 5, 6, 7, 8]
    var timeSignature: (beatsPerMeasure: Int, noteDuration: Int) = (4,4)
    var previousTimeSignature: (beatsPerMeasure: Int, noteDuration: Int) = (4,4)

    //Note Durations
    var noteDurationValue: [Int] = [ 4, 8, 12, 16, 20, 24]
    var noteDurationImage: [UIImage] = [
        UIImage(named: "Quarters.png")!,
        UIImage(named: "Eighths.png")!,
        UIImage(named: "Triplets.png")!,
        UIImage(named: "Sixthteenths.png")!,
        UIImage(named: "Quintuplets.png")!,
        UIImage(named: "Sixtuplets.png")!
    ]
    
    
    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return beatsPerMeasure.count
        } else {
            return noteDurationValue.count
        }
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36.0
    }
    
    //viewForRow
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var textView: UIView
        var imageView: UIImageView
        
        if(view == nil){
            if component == 0 {
                let title = "\(beatsPerMeasure[row])"
                textView = UIView()
                let label = UILabel(frame: CGRectMake(25, 0, 40, 60))
                label.text = title
                label.font = UIFont(name: label.font.fontName, size: 24)
                label.textColor = UIColor(red: 195/256, green: 196/256, blue: 198/256 , alpha: 1.0)
                textView.frame = CGRectMake(0, 0, 40, 60)
                textView.contentMode = UIViewContentMode.Center
                textView.addSubview(label)
                return textView
            } else {
                let image = noteDurationImage[row]
                imageView = UIImageView()
                imageView.image = image
                imageView.frame = CGRectMake(0, 0, 40, 60)
                imageView.contentMode = UIViewContentMode.Center
                return imageView
            }
        } else {
            imageView = UIImageView()
            return imageView
        }
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // selected value in Uipickerview in Swift
        if component == 0 {
            timeSignature.beatsPerMeasure = beatsPerMeasure[row]
            beatAccentLabel.text = "\(timeSignature.beatsPerMeasure)"
        } else if component == 1 {
            timeSignature.noteDuration = noteDurationValue[row]
            noteDurationImageView.image = noteDurationImage[row]
        }
        
        if (timeSignature.beatsPerMeasure != previousTimeSignature.beatsPerMeasure) {
            if (timeSignature.beatsPerMeasure == 1) {
                accenting = false
            } else {
                accenting = true
            }
            resetTimer()
        }
        if (timeSignature.noteDuration != previousTimeSignature.noteDuration) {
            if (metronomeIsPlaying) {
                resetTimer()
            }
            if (timeSignature.beatsPerMeasure == 1 && timeSignature.noteDuration == 4) {
                accenting = false
            } else {
                accenting = true
            }
        }
        previousTimeSignature.beatsPerMeasure = timeSignature.beatsPerMeasure
        previousTimeSignature.noteDuration = timeSignature.noteDuration
    }
}



//    func gestureSetup() {
////        let tapGestureRecognizer = UIPanGestureRecognizer(target: self, action: "tapGesture:")
////        tapTempoButton.addGestureRecognizer(tapGestureRecognizer)
//
//        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressed:")
//        longPressRecognizer.minimumPressDuration = 1.0
//        tapTempoButton.addGestureRecognizer(longPressRecognizer)
//    }
//
//    func tapGesture(sender: UIGestureRecognizer) {
//        if sender.state == UIGestureRecognizerState.Began {
//            print("tap")
//        }
//    }
//
//    func longPressed(sender: UIGestureRecognizer) {
//        noLongPress = false
////        if sender.state == UIGestureRecognizerState.Ended {
////            playPause(playButton)
////            noLongPress = true
////        }
//    }