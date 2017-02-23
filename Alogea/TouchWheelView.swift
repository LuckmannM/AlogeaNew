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
    
    @IBOutlet var panRecogniser: UIPanGestureRecognizer!
    @IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet var zeroHeightConstraint: NSLayoutConstraint!
    
    var logoView: UIImageView!
    
    let π: CGFloat = CGFloat(M_PI)
    let margin: CGFloat = 5.0
    let themeColors = ColorScheme.sharedInstance()
    let gradientBar = UIImage(named: "GradientBar2")
    let gradientBarHeight = UIImage(named: "GradientBar2")!.size.height - 1
    let circleSegment: CGFloat = 2 * CGFloat(M_PI) / 1280 // 256
    
    var delegate: TouchWheelDelegate!
    var mainButtonController: MVButtonController!
    var mainViewController: MainViewController!
    
    var color = UIColor()
    var circleRim = UIBezierPath()
    var arrowTriangle = UIBezierPath()
    var lineWidth: CGFloat {
        return frame.height / 5
    }
    var startAngle, endAngle: CGFloat!
    var radius: CGFloat!
    var centerPoint, colorPosition: CGPoint!
    
    var touchPoint = CGPoint.zero
    var touchWheelValue: Double = 0.0
    
    var innerRect: CGRect {
        return bounds.insetBy(dx: lineWidth + margin, dy: lineWidth + margin)
    }
    class func sharedInstance() -> TouchWheelView {
        return touchWheel
    }
    
    override init(frame: CGRect) {

        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("init TOuchWheel")
        mainViewController = (UIApplication.shared.delegate as! AppDelegate).mainView //tabBarViews[0] as! MainViewController
        mainButtonController = MVButtonController(viewRect: CGRect.zero, touchWheel: self, mainViewController: self.mainViewController)
        logoView = UIImageView(image: UIImage(named: "CircularLogo"))
        logoView.alpha = 0.7
        insertSubview(logoView, belowSubview: mainButtonController.buttonView)
        print("finished init TouchWheel")
    }
    
    func switchConstraints(forLandScape:Bool) {
        if forLandScape {
            aspectRatioConstraint.isActive = false
            zeroHeightConstraint.isActive = true
        } else {
            aspectRatioConstraint.isActive = true
            zeroHeightConstraint.isActive = false
        }
        touchWheel.layoutIfNeeded()

    }
    
    // MARK: - drawing functions
    override func draw(_ rect: CGRect) {
        
        if rect.height <= 0 { return } // avoids re-drawing in landScape mode when the view is 'squashed'
        logoView.frame = bounds.insetBy(dx: bounds.width * 0.05, dy: bounds.height * 0.05)
        
        // self.frame is only available in correct size while drawing, not after init() from NIB; it's then set to 0,0,1000,1000
        startAngle = 2 * π // ('east')
        endAngle = startAngle - circleSegment
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
            startAngle = endAngle + circleSegment // / 5
            endAngle = endAngle - circleSegment // * 4/5
        }
        
        drawArcSegment(startAngle: startAngle, endAngle: 2 * π)
        
        context!.restoreGState()
        
        arrowTriangle.move(to: CGPoint(x: bounds.midX - 1, y: margin))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX, y: margin))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX, y: margin))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX, y: margin + lineWidth))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX - 2, y: margin + lineWidth))
        arrowTriangle.addLine(to: CGPoint(x: bounds.midX - 1/3 * lineWidth, y: margin + lineWidth/2))
        gradientBar?.getPixelColor(pos: CGPoint(x: 5, y: 0.99 * gradientBarHeight)).setFill()
        arrowTriangle.fill()
        
        mainButtonController.sizeViews(rect: innerRect)
    }
    
    private func drawArcSegment(startAngle: CGFloat, endAngle: CGFloat) {
        
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
    
    @IBAction func touchGesture(recogniser: UIPanGestureRecognizer) {
        
        let π: Float = Float(M_PI)
        var angle: Float = 0.0
        
        if recogniser.state == .began {
            touchPoint = recogniser.location(in: self)
        }
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
        
        if self.layer.pixelIsOpaque(point: touchPoint) && self.getPixelColor(fromPoint: touchPoint) != mainButtonController.buttonView.buttonColor {
            touchWheelValue = Double(10 * angle / (2 * π))
            if recogniser.state == .ended {
                delegate.passOnTouchWheelScore(score: touchWheelValue, ended: true)
            } else {
                delegate.passOnTouchWheelScore(score: touchWheelValue, ended: false)
            }
        }
    }
    
    func disable() {
        panRecogniser.isEnabled = false
        mainButtonController.roundButton.isEnabled = false
        
    }
    
    func enable() {
        panRecogniser.isEnabled = true
        mainButtonController.roundButton.isEnabled = true
    }
        
}

let touchWheel = TouchWheelView()

