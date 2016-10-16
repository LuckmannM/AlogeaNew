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
    
    init(viewRect: CGRect, touchWheel: TouchWheelView) {
        touchWheel.delegate = self
        buttonView = MVButtonView(frame: viewRect, controller: self)
        roundButton = MainViewButton(frame: viewRect, containingView: buttonView)
    }
    
    func passOnTouchWheelScore(score: Double,ended: Bool? = false) {
        
        buttonView.displayScore(score: score, ended: ended)
    }
   
}
