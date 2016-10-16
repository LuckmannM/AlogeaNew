//
//  MVButtonController.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit

class MVButtonController: TouchWheelDelegate {
    
    var buttonView: MVButtonView!
    var roundButton: MainViewButton!
    var touchWheel: TouchWheelView!
    
    init(viewRect: CGRect, touchWheel: TouchWheelView) {
        self.touchWheel = touchWheel
        touchWheel.delegate = self
        buttonView = MVButtonView(frame: viewRect, controller: self)
        roundButton = MainViewButton(frame: viewRect, controller: self)
    }
    
    func passOnTouchWheelScore(score: Double,ended: Bool? = false) {
        
        buttonView.displayScore(score: score, ended: ended)
    }
   
}
