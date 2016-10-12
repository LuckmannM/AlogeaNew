//
//  TouchWheelView.swift
//  Alogea
//
//  Created by mikeMBP on 12/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class TouchWheelView: UIView {
    
    let π: CGFloat = CGFloat(M_PI)
    let themeColors = ColorScheme.sharedInstance()
    let gradientBar = UIImage(named: "GradientBar")
    let gradientBarHeight = UIImage(named: "GradientBar")!.size.height
    
    var color = UIColor()
    var circleRim = UIBezierPath()
    
    var lineWidth: CGFloat!
    var startAngle, endAngle: CGFloat!
    var circleSegment: CGFloat!
    var radius: CGFloat!
    var centerPoint, colorPosition: CGPoint!
    
    
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        self.backgroundColor = themeColors.gradientGreen
        
        circleSegment = 2 * π / 256
        startAngle = 2 * π // ('east')
        endAngle = startAngle - circleSegment
        lineWidth = frame.height / 10
        radius = -lineWidth + frame.height / 2
        
        centerPoint = CGPoint(x: frame.midX, y: frame.midY)
        print("TWView data: frame: \(frame)")
        print("center: \(centerPoint)")
        print("radius: \(radius)")
        print("lineWidth: \(lineWidth)")
        //        context!.saveGState()
        //        context!.translateBy(x: 0, y: frame.height)
        //        context!.rotate(by: -π / 2)
        
        circleRim.addArc(withCenter: centerPoint, radius: (radius), startAngle: 2 * π, endAngle: 0, clockwise: false)
        themeColors.darkBlue.setStroke()
        circleRim.lineWidth = lineWidth + 2
        circleRim.stroke()
        
        while endAngle >= 0 {
            
            drawArcSegment(startAngle: startAngle, endAngle: endAngle)
            startAngle = endAngle + circleSegment / 5
            endAngle = endAngle - circleSegment * 4/5
        }
        
        drawArcSegment(startAngle: startAngle, endAngle: 2 * π)
        
        //        context!.restoreGState()
        
    }
    
    
    func drawArcSegment(startAngle: CGFloat, endAngle: CGFloat) {
        
        if (gradientBar != nil) {
            colorPosition = CGPoint(x: 5, y: gradientBarHeight * ((2 * π - startAngle) / (2 * π)))
            color = (gradientBar?.getPixelColor(pos: colorPosition))!
        } else {
            color = themeColors.gradientRed
        }
        
        let circlePath = UIBezierPath()
        circlePath.addArc(withCenter: centerPoint,
                          radius: radius,
                          startAngle: startAngle,
                          endAngle: endAngle,
                          clockwise: false
        )
        
        circlePath.lineWidth = lineWidth
        color.setStroke()
        circlePath.stroke()
        
    }
    
}

