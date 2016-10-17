//
//  MVButtonController.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//
// This class provides the 'organising class' for the MVButtonView, including initialising and providing the sizing/positioning of MVButtonView
// This controller adds the MVButtonView (with it's subViews) as subView to TouchWheelView. TouchViewWheel is an IB UIView object
// it is itself initialised by the TouchWheelView receiving from it the frame, wheelWidth and margins; the sizeButtonView func is called from TWV.draw
// it is the Delegate of touchWheel receiving the scoreValue and passing it to buttonView to display
// varButtonView contains the scoreLabel and initiates the MVButton itself based on position and size it received from it's controller


import Foundation
import UIKit
import CoreData

class MVButtonController: TouchWheelDelegate, MVButtonDelegate {
    
    var buttonView: MVButtonView!
    weak var roundButton: MVButton!
    weak var touchWheel: TouchWheelView!
//    weak var mainViewController: MainViewController!
    
    init(viewRect: CGRect, touchWheel: TouchWheelView) {
        self.touchWheel = touchWheel
        touchWheel.delegate = self
        buttonView = MVButtonView(frame: viewRect, controller: self)
        roundButton = buttonView.roundButton as! MVButton!
        touchWheel.addSubview(buttonView)
//        mainViewController = MainViewController.sharedInstance()
    }
    
    func sizeButtonViews(rect: CGRect, touchWheelWidth: CGFloat, margins: CGFloat) {

        let innerRect = CGRect(
            x: margins + touchWheelWidth,
            y: margins + touchWheelWidth,
            width: rect.width - (2 * margins + touchWheelWidth * 2),
            height: rect.height - (2 * margins + touchWheelWidth * 2)
        )
        buttonView.frame = innerRect
        roundButton.frame = buttonView.bounds
        
        buttonView.setNeedsDisplay()
        roundButton.setNeedsDisplay()
        
    }
    
    func passOnTouchWheelScore(score: Double,ended: Bool = false) {
        
        buttonView.displayScore(score: score)
        
        if ended {
            
            //*** display buttonView.picker with cancel, now, 15 min ago etc
            
            buttonView.hideScore()
            // create score event
        }
    }
    
    func mvButtonTapped(sender: MVButton) {
        buttonView.showPicker()
    }
    
    // MARK: - diaryEntryWindow
    
    func requestDiaryEntryWindow() {
        
//        mainViewController.showDiaryEntryWindow()
        
//        let diaryEntryWindow = UIView(frame: touchWheel.bounds)
//        
//        diaryEntryWindow.backgroundColor = UIColor(colorLiteralRed: 248/255, green: 248/255, blue: 245/255, alpha: 0.8)
//        diaryEntryWindow.frame = CGRect(origin: CGPoint(x: 0, y: touchWheel.frame.maxY), size: touchWheel.frame.size)
//        
//        let textView: UITextView = {
//            let tV = UITextView()
//            tV.frame = diaryEntryWindow.bounds.insetBy(dx: 5, dy: 30)
//            tV.backgroundColor = UIColor.clear
//            tV.text = "Enter your diary text here"
//            tV.font = UIFont(name: "AvenirNext-UltraLight", size: 22)
//            tV.textColor = UIColor.black
//            return tV
//        }()
//        diaryEntryWindow.addSubview(textView)
//        mainViewController.view.addSubview(diaryEntryWindow)
//        
//        UIView.animate(withDuration: 0.5, animations: {
//            diaryEntryWindow.frame = self.touchWheel.frame.offsetBy(dx: 0, dy: -200)
//        })
//        
//        textView.becomeFirstResponder()
//        textView.frame.offsetBy(dx: 0, dy: -200)

    }

       
}
