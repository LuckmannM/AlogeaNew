//
//  FloatingMenuView.swift
//  Alogea
//
//  Created by mikeMBP on 22/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class FloatingMenuView: UIView {

    
    @IBOutlet weak var graphContainerView: GraphContainerView!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet var graphTypeButton: UIButton!
    @IBOutlet var printButton: UIButton!
    @IBOutlet var toggleEventView: UIButton!
    @IBOutlet weak var graphView:GraphView!
    
    let arrowInset: CGFloat = 10
    var stickOutWidth: CGFloat! = 70
    var arrowHeight: CGFloat!
    var arrowPath: UIBezierPath!
    
    var ibViewFrame = CGRect()

    override func draw(_ rect: CGRect) {
        // Drawing code
        
        arrowPath = UIBezierPath()
        arrowHeight = 4/5 * frame.height
        
        if graphTypeButton.isEnabled {
            arrowPath.move(to: CGPoint(x: rect.maxX - 5, y: rect.midY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - arrowInset , y: rect.midY))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.midY + arrowHeight/2))
        } else {
            arrowPath.move(to: CGPoint(x: rect.maxX - arrowInset, y: rect.midY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - 5 , y: rect.midY))
            arrowPath.addLine(to: CGPoint(x: rect.maxX - arrowInset, y: rect.midY + arrowHeight/2))
        }
        
        UIColor.lightGray.setStroke()
        arrowPath.lineWidth = 3.0
        arrowPath.stroke()
        
    }
    
    @IBAction func slideOut(tap: UITapGestureRecognizer) {
        
        let targetHeight = 3/4 * graphContainerView.frame.height
        let targetY = graphContainerView.bounds.midY - targetHeight/2
        
        ibViewFrame = frame

        UIView.animate(withDuration: 0.5, animations: {
            self.frame = CGRect(x: self.frame.minX, y: targetY, width: self.frame.width, height: targetHeight)
            self.frame = self.frame.offsetBy(dx: self.stickOutWidth, dy: 0)
            self.alpha = 0.8
            }, completion: { (value: Bool) in
                
                self.setNeedsDisplay()
                self.tapGesture.removeTarget(self, action: #selector(self.slideOut))
                self.tapGesture.addTarget(self, action: #selector(self.slideIn))
                self.graphTypeButton.isEnabled = true
        })
        
        printButton.isEnabled = true
        graphTypeButton.isEnabled = true
//        listButton.isEnabled = true

    }
    
    @IBAction func graphButtonAction(sender: UIButton) {
        
        if graphTypeButton.tag == 0 {
            //graphView.graphIsLineType = false
            UserDefaults.standard.set(true, forKey: "GraphIsLine")
            graphTypeButton.setImage(UIImage(named: "GraphButtonLine"), for: .normal)
            graphTypeButton.tag = 1
        } else {
            //graphView.graphIsLineType = true
            UserDefaults.standard.set(false, forKey: "GraphIsLine")
            graphTypeButton.tag = 0
            graphTypeButton.setImage(UIImage(named: "GraphButtonBar"), for: .normal)
        }
        graphView.setNeedsDisplay()
    }
    
    @IBAction func toggleEventsView(sender: UIButton) {
        
        let medsView = graphView.medsView
        
        if (UserDefaults.standard.bool(forKey: "MedsViewEnabled")) {
            UserDefaults.standard.set(false, forKey: "MedsViewEnabled")
            
            UIView.animate(withDuration: 0.7, animations: {
                medsView?.alpha = 0.0
            }, completion:  { (value: Bool) in
                self.slideIn()
            })
            
        } else {
            UserDefaults.standard.set(true, forKey: "MedsViewEnabled")
            medsView?.setNeedsDisplay()
            
            UIView.animate(withDuration: 0.7, animations: {
                medsView?.alpha = 1.0
            }, completion:  { (value: Bool) in
                self.slideIn()
            })
        }
    }

    
    func slideIn() {
        
        UIView.animate(withDuration: 0.5, animations: {
            self.frame = self.frame.offsetBy(dx: -self.stickOutWidth, dy: 0)
            self.alpha = 0.5
            
            }, completion: { (value: Bool) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.frame = self.ibViewFrame
                    self.graphTypeButton.isEnabled = false

                })
                self.setNeedsDisplay()
                self.tapGesture.removeTarget(self, action: #selector(self.slideIn))
                self.tapGesture.addTarget(self, action: #selector(self.slideOut))
                self.printButton.isEnabled = false
                self.graphTypeButton.isEnabled = false
        })
        
    }


}
