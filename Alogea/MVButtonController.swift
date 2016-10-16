//
//  MVButtonController.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//
// This class provides the 'organising class' for the MVButtonView, including initialising and providing the sizing/positioning of MVButtonView
// This controller adds the MVButtonView (with it's subViews) as subView to TouchWheelView
// it is itself initialised by the TouchWheelView receiving from it the frame, wheelWidth and margins; the sizeButtonView func is called from TWV.draw
// it is the Delegate of touchWheel receiving the scoreValue and passing it to buttonView to display
// MVButtonView contains the scoreLabel and initiates the MVButton itself based on position and size it received from it's controller


import Foundation
import UIKit

class MVButtonController: TouchWheelDelegate {
    
    var buttonView: MVButtonView!
    weak var roundButton: MVButton!
    weak var touchWheel: TouchWheelView!
    
    init(viewRect: CGRect, touchWheel: TouchWheelView) {
        self.touchWheel = touchWheel
        touchWheel.delegate = self
        buttonView = MVButtonView(frame: viewRect, controller: self)
        roundButton = buttonView.roundButton as! MVButton!
        touchWheel.addSubview(buttonView)
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
    
    
    func passOnTouchWheelScore(score: Double,ended: Bool? = false) {
        
        buttonView.displayScore(score: score, ended: ended)
    }
   
}
