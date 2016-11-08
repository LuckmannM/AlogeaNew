//
//  MVButton.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

protocol MVButtonDelegate {
    func mvButtonTapped(sender: MVButton)
}

class MVButton: UIButton {
    
    var touchWheel: TouchWheelView!
    var colors: ColorScheme!
    weak var containingView: MVButtonView!
    var delegate: MVButtonDelegate!
    var controller: MVButtonController!
    
    convenience init(frame: CGRect, controller: MVButtonController) {
        self.init(frame: frame)
        self.init(type: .custom)
        self.delegate = controller
        self.controller = controller
        self.touchWheel = controller.touchWheel
        colors = ColorScheme.sharedInstance()
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func draw(_ rect: CGRect) {
        let buttonCircle = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        colorScheme.lightGray.setFill()
        buttonCircle.fill()
        
        colorScheme.darkBlue.setStroke()
        buttonCircle.lineWidth = 1
        buttonCircle.stroke()
        
        let crossPath = UIBezierPath()
        crossPath.move(to: CGPoint(x: bounds.midX - frame.width * 0.25, y: bounds.midY))
        crossPath.addLine(to: CGPoint(x: bounds.midX + frame.width * 0.25 , y: bounds.midY))
        
        crossPath.move(to: CGPoint(x: bounds.midX, y: bounds.midY - bounds.height * 0.25))
        crossPath.addLine(to: CGPoint(x: bounds.midX, y: bounds.midY + bounds.height * 0.25))
        
        crossPath.lineWidth = 2.0
        crossPath.stroke()

    }
    
    func tapped() {
        enlargeButtonView()
    }
    
    func enlargeButtonView(withTap:Bool = true) {
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            
            let targetRect = CGRect(origin: .zero, size: CGSize(width: self.controller.touchWheel.frame.width, height: self.controller.touchWheel.frame.height))
            self.controller.buttonView.frame = targetRect
            self.frame = targetRect
            
            }, completion: { (value: Bool) in
                if withTap == true {
                    self.delegate.mvButtonTapped(sender: self)
                }
        })
        
    }
    
}
