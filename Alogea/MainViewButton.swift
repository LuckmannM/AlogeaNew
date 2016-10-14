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
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func passOnTouchWheelScore(score: Double) {
        let scoreNumber = NSNumber(value: score)
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            return formatter
        }()
    
        scoreLabel.text = numberFormatter.string(from: scoreNumber)
        print("MVButton label set to \(numberFormatter.string(from: scoreNumber)) ")
    }

}
