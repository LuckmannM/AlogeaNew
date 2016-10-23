//
//  FloatingMenuView.swift
//  Alogea
//
//  Created by mikeMBP on 22/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class FloatingMenuView: UIView {

    let arrowInset: CGFloat = 20
    var arrowHeight: CGFloat!
    var arrowPath: UIBezierPath!
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        arrowPath = UIBezierPath()
        arrowHeight = 4/5 * frame.height
        
        if self.frame.minX < 0 {
            arrowPath.move(to: CGPoint(x: rect.maxX - arrowInset, y: rect.midY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - 10 , y: rect.midY))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - arrowInset, y: rect.midY + arrowHeight/2))
        } else {
            arrowPath.move(to: CGPoint(x: rect.maxX - 10, y: rect.midY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - arrowInset , y: rect.midY))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - arrowInset, y: rect.midY + arrowHeight/2))
        }
        
        UIColor.lightGray.setStroke()
        arrowPath.lineWidth = 8.0
        arrowPath.stroke()
        
    }

}
