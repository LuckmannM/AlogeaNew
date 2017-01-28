//
//  MedsView.swift
//  Alogea
//
//  Created by mikeMBP on 27/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

class MedsView: UIView {
    
    
    var graphView: GraphView!
    var helper: GraphViewHelper!
    var medController: MedicationController!
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(graphView: GraphView) {
        self.init()
        print("init MedsView... ")

        self.graphView = graphView
        self.helper = graphView.helper
        self.frame = graphView.bounds
        self.backgroundColor = UIColor.clear
        
        self.medController = MedicationController.sharedInstance()
        print("...init MedsView end")

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing methods
    
    override func draw(_ rect: CGRect) {
        
        let medRects = medController.medViewRegularMedRects(minDate: graphView.minDisplayDate, maxDate: graphView.maxDisplayDate, displayWidth: frame.width)
        let cornerRadius: CGFloat = 8.0 / 2
        let barsPath = UIBezierPath()
        
        let verticalOffset = bounds.maxY - helper.timeLineSpace()
        for rect in medRects {
            let shiftedRect = rect.offsetBy(dx: 0, dy: verticalOffset)
            let medRectPath = UIBezierPath(roundedRect: shiftedRect, cornerRadius: cornerRadius)
            barsPath.append(medRectPath)
        }
        
        barsPath.lineWidth = 1.0
        UIColor.white.setStroke()
        barsPath.stroke()
        colorScheme.medBarGreen.setFill()
        barsPath.fill()
    }

}
