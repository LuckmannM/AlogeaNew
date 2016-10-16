//
//  MVButtonView.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class MVButtonView: UIView {

    var scoreLabel: UILabel!
    var roundButton: UIButton!
    var colorScheme: ColorScheme!
    weak var touchWheel: TouchWheelView!

    convenience init(frame: CGRect, controller: MVButtonController) {
        self.init(frame: frame)
        self.backgroundColor = UIColor.clear
        colorScheme = ColorScheme.sharedInstance()
        scoreLabel = {
            let label = UILabel()
            label.text = "0.0"
            label.font = UIFont.boldSystemFont(ofSize: 64)
            label.textColor = colorScheme.darkBlue
            label.isHidden = true
            return label
        }()
        addSubview(scoreLabel)
        
        roundButton = MainViewButton(frame: CGRect.zero, controller: controller)
        addSubview(roundButton)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        roundButton.frame = bounds
        roundButton.setNeedsDisplay()
        
        let buttonCircle = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        colorScheme.seaGreen.setFill()
        buttonCircle.fill()
        
        colorScheme.darkBlue.setStroke()
        buttonCircle.lineWidth = 1
        buttonCircle.stroke()
    }
    
    func displayScore(score: Double,ended: Bool? = false) {
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
        roundButton.isHidden = true
        scoreLabel.isHidden = false
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
