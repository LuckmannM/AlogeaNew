//
//  MainViewButton.swift
//  Alogea
//
//  Created by mikeMBP on 14/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class MainViewButton: UIButton, TouchWheelDelegate {
    
    var scoreLabel: UILabel!
    var colorScheme: ColorScheme!
    weak var touchWheel: TouchWheelView!
        
    convenience init(frame: CGRect, containingView: TouchWheelView) {
        self.init(frame: frame)
        self.touchWheel = containingView
        self.touchWheel.delegate = self
        self.backgroundColor = UIColor.clear
        colorScheme = ColorScheme.sharedInstance()
        scoreLabel = {
            let label = UILabel()
            label.text = "0.0"
            label.font = UIFont.boldSystemFont(ofSize: 64)
            label.textColor = colorScheme.darkBlue
            return label
        }()
        addSubview(scoreLabel)
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
        buttonCircle.lineWidth = 1
        buttonCircle.stroke()
        
        centerScoreLabel()
        
//        print("label frame = \(scoreLabel.frame)")
//        let realCenter = CGPoint(x: scoreLabel.frame.origin.x + scoreLabel.frame.width / 2, y: scoreLabel.frame.origin.y + scoreLabel.frame.height / 2)
//        print("frame real center is \(realCenter)")
//        print("'center' is \(scoreLabel.center)")
//        let mid = CGPoint(x: scoreLabel.frame.midX, y: scoreLabel.frame.midY)
//        print("'mid-' is \(mid)")
//        print("MVButton center = \(center)")
        
    }
    
    func passOnTouchWheelScore(score: Double) {
        let scoreNumber = NSNumber(value: score)
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
            formatter.minimumIntegerDigits = 1
            return formatter
        }()
    
        scoreLabel.text = numberFormatter.string(from: scoreNumber)
        centerScoreLabel()
    }
    
    func centerScoreLabel() {
        scoreLabel.sizeToFit()
        scoreLabel.frame = CGRect(
            x: frame.width / 2 - scoreLabel.frame.width / 2,
            y: frame.height / 2 - scoreLabel.frame.height / 2,
            width: scoreLabel.frame.width,
            height: scoreLabel.frame.height
        )
        
    }

}
