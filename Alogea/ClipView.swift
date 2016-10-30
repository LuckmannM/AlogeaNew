//
//  ClipView.swift
//  Alogea
//
//  Created by mikeMBP on 29/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class ClipView: UIView {

    
    @IBOutlet weak var graphView:GraphView!
    
//    let timeLineTickLength: CGFloat = 5.0
//    let timeLineLabelHeight: CGFloat = {
//        let label = UILabel()
//        label.font = UIFont(name: "AvenirNext-Regular", size: 12.0)
//        label.text = "30.12.2020"
//        label.sizeToFit()
//        return label.frame.height
//    }()

    
    override func draw(_ rect: CGRect) {
        
            let xStart: CGFloat = bounds.origin.x
            let xEnd: CGFloat = bounds.maxX
        
            let upperLineY = bounds.minY + 1.0
            let lowerLineY = bounds.maxY - GraphViewHelper.sharedInstance().timeLineSpace()
            let midLineY = (upperLineY + lowerLineY) / 2 + 0.5
            
            
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: xStart, y: upperLineY))
            linePath.addLine(to: CGPoint(x: xEnd, y: upperLineY))
            
            linePath.move(to: CGPoint(x: xStart, y: midLineY))
            linePath.addLine(to: CGPoint(x: xEnd, y: midLineY))
            
            linePath.move(to: CGPoint(x: xStart, y:lowerLineY))
            linePath.addLine(to: CGPoint(x: xEnd, y: lowerLineY))
            
            
            colorScheme.lightGray.withAlphaComponent(0.5).setStroke()
            linePath.lineWidth = 2.0
            linePath.stroke()
        }

}
