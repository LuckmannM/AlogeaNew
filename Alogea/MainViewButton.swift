//
//  MainViewButton.swift
//  Alogea
//
//  Created by mikeMBP on 14/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class MainViewButton: UIButton, TouchWheelDelegate {
    
    var scoreLabel = UILabel()
    var colorScheme: ColorScheme!
    weak var touchWheel: TouchWheelView!
        
    convenience init(frame: CGRect, containingView: TouchWheelView) {
        self.init(frame: frame)
        self.touchWheel = containingView
        self.touchWheel.delegate = self
        self.backgroundColor = UIColor.clear
        colorScheme = ColorScheme.sharedInstance()
        scoreLabel.text = "0.0"
        scoreLabel.sizeToFit()
        scoreLabel.center = self.center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    override func draw(_ rect: CGRect) {
        let buttonCircle = UIBezierPath(ovalIn: bounds)
        colorScheme.seaGreen.setFill()
        buttonCircle.fill()
        colorScheme.darkBlue.setStroke()
        buttonCircle.lineWidth = 2
        buttonCircle.stroke()
    }
    
    func passOnTouchWheelScore(score: Double) {
        let scoreNumber = NSNumber(value: score)
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            return formatter
        }()
    
        scoreLabel.text = numberFormatter.string(from: scoreNumber)
        scoreLabel.sizeToFit()
        scoreLabel.center = self.center
        print("MVButton label set to \(numberFormatter.string(from: scoreNumber)) ")
    }

}
