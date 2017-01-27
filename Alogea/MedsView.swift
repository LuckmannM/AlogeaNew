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
        self.frame = graphView.frame
        self.backgroundColor = UIColor.clear
        
        self.medController = MedicationController.sharedInstance()
        print("...init MedsView end")

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing methods
    
    override func draw(_ rect: CGRect) {
        
        self.frame = graphView.frame
        
        print("MedView draw...")
        print("MedView width = \(frame.width)")
        print("GraphView width = \(graphView.frame.width)")

        
        let medRects = medController.medViewRegularMedRects(minDate: graphView.minDisplayDate, maxDate: graphView.maxDisplayDate, displayWidth: frame.width)
        /*
        let barWidth: CGFloat = 5.0
        */
        
        let cornerRadius: CGFloat = 8.0 / 6
        let barsPath = UIBezierPath()
        
        let verticalOffset = frame.maxY - helper.timeLineSpace() - 25
                    print("vertOffset is \(verticalOffset), timeLineSpace = \(helper.timeLineSpace())")
                    print("medView frame is \(frame)")
        for rect in medRects {
            let shiftedRect = rect.offsetBy(dx: 0, dy: verticalOffset)
            let medRectPath = UIBezierPath(roundedRect: shiftedRect, cornerRadius: cornerRadius)
            barsPath.append(medRectPath)
            print("medRect is \(shiftedRect)")
        }
        
        barsPath.lineWidth = 1.0
        UIColor.white.setStroke()
        barsPath.stroke()
        colorScheme.medBarGreen.setFill()
        barsPath.fill()
        
        print("...end MedView draw")

    }

}
