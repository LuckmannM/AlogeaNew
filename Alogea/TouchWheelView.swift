//
//  TouchWheelView.swift
//  Alogea
//
//  Created by mikeMBP on 12/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

protocol TouchWheelDelegate {
    func passOnTouchWheelScore(score: Double,ended: Bool)
}

class TouchWheelView: UIView {
    
    let π: CGFloat = CGFloat(M_PI)
    let margin: CGFloat = 5.0
    let themeColors = ColorScheme.sharedInstance()
    let gradientBar = UIImage(named: "GradientBar")
    let gradientBarHeight = UIImage(named: "GradientBar")!.size.height
    let circleSegment: CGFloat = 2 * CGFloat(M_PI) / 256
    
    var delegate: TouchWheelDelegate!
    var mainButtonController: MVButtonController!
    var mainViewController: MainViewController!
    
    var color = UIColor()
    var circleRim = UIBezierPath()
    var arrowTriangle = UIBezierPath()
    var lineWidth: CGFloat!
    var startAngle, endAngle: CGFloat!
    var radius: CGFloat!
    var centerPoint, colorPosition: CGPoint!
    
    var touchPoint = CGPoint.zero
    var touchWheelValue: Double = 0.0
    
    class func sharedInstance() -> TouchWheelView {
        return touchWheel
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        mainViewController = (UIApplication.shared.delegate as! AppDelegate).tabBarViews[0] as! MainViewController
        mainButtonController = MVButtonController(viewRect: CGRect.zero, touchWheel: self, mainViewController: self.mainViewController)
    }
    
    // MARK: - drawing functions
    override func draw(_ rect: CGRect) {
        
        if rect.height <= 0 { return } // avoids re-drawing in landScape mode when the view is 'squashed'
                
        // self.frame is only available in correct size while drawing, not after init() from NIB; it's then set to 0,0,1000,1000
        startAngle = 2 * π // ('east')
        endAngle = startAngle - circleSegment
        lineWidth = frame.height / 5
        radius = -margin - lineWidth / 2 + frame.height / 2
        centerPoint = CGPoint(x: frame.height / 2, y: frame.width / 2)
        
        let context = UIGraphicsGetCurrentContext()

        context!.saveGState()
        context!.translateBy(x: 0, y: frame.height)
        context!.rotate(by: -π / 2)
        
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
        
        context!.restoreGState()
        
        arrowTriangle.move(to: CGPoint(x: bounds.midX, y: margin))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX, y: margin + lineWidth))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX - 1/3 * lineWidth, y: margin + lineWidth/2))
        gradientBar?.getPixelColor(pos: CGPoint(x: 5, y: 0.97 * gradientBarHeight)).setFill()
        arrowTriangle.fill()
        
        mainButtonController.sizeButtonViews(rect: frame, touchWheelWidth: lineWidth, margins: margin)
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
    
    // MARK: - gestureFunctions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // to get initial touch location before pan starts
        // this initial touchLocation is not available from the PanGestureRecogniser
        for touch: AnyObject in touches {
            touchPoint = touch.location(in: self)
        }

    }
    
    @IBAction func touchGesture(recogniser: UIPanGestureRecognizer) {
        
        let π: Float = Float(M_PI)
        var angle: Float = 0.0
        
        let translate = recogniser.translation(in: self)
        
        touchPoint.x += translate.x
        touchPoint.y += translate.y
        recogniser.setTranslation(CGPoint.zero, in: self)
 
        let distanceFromCentre = CGPoint(
            x: (touchPoint.x - self.frame.width / 2),
            y: (touchPoint.y - self.frame.height / 2 )
        )
        
        // red/green wheel transition at top  - due to overlap in gradient arc drawing - is at ca. 3º 'east'
        // so add slightly more than π/2 to align 0 angle to border
        angle = atan2f(Float(distanceFromCentre.y),Float(-distanceFromCentre.x)) + π / 1.9
        
        if angle < 0 {
            angle += 2 * π
        }
        
        if self.layer.pixelIsOpaque(point: touchPoint) {
            touchWheelValue = Double(10 * angle / (2 * π))
            if recogniser.state == .ended {
                delegate.passOnTouchWheelScore(score: touchWheelValue, ended: true)
            } else {
                delegate.passOnTouchWheelScore(score: touchWheelValue, ended: false)
            }
        }
    }
        
}

let touchWheel = TouchWheelView()

