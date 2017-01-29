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
        
        let regMedRects = medController.medViewRegularMedRects(minDate: graphView.minDisplayDate, maxDate: graphView.maxDisplayDate, displayWidth: frame.width)
        let prnMedRects = eventsDataController.medViewPRNMedRects(minDate: graphView.minDisplayDate, maxDate: graphView.maxDisplayDate, displayWidth: frame.width)
        let cornerRadius: CGFloat = 8.0 / 2
        // let regBarsPath = UIBezierPath()
        // let prnBarsPath = UIBezierPath()
        
        let verticalOffset = bounds.maxY - helper.timeLineSpace()
        var topOfRegMedRects = verticalOffset // to find vertical lowest position for prnMedRect
        
        UIColor.white.setStroke()
        
        var count = 0
        for rect in regMedRects {
            var shiftedRect = rect.offsetBy(dx: 0, dy: verticalOffset)
            
            // ensure medRects don't overlap, otherwise shift rect up by 5
//            if count > 0 {
//                if rect.intersects(regMedRects[count - 1]) {
//                    shiftedRect = rect.offsetBy(dx: 0, dy: verticalOffset - 10)
//                }
//                
//            }
            
            for i in 0..<count {
                if rect.intersects(regMedRects[i]) {
                    shiftedRect = rect.offsetBy(dx: 0, dy: verticalOffset - 12)
                    if shiftedRect.minY < topOfRegMedRects {
                        // ensure prnMedRect are positoned higher than regMedRects
                        topOfRegMedRects = shiftedRect.minY - 12
                    }
                }
            }

            let medRectPath = UIBezierPath(roundedRect: shiftedRect, cornerRadius: cornerRadius)
            // regBarsPath.append(medRectPath)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[count].setFill()
            medRectPath.fill()
            medRectPath.stroke()
            count += 1
        }
        
        count = 0
        for rect in prnMedRects {
            var shiftedRect = rect.offsetBy(dx: 0, dy: topOfRegMedRects)
            
            // ensure medRects don't overlap, otherwise shift rect up by 5
            if count > 0 {
                if rect.intersects(prnMedRects[count - 1]) {
                    shiftedRect = rect.offsetBy(dx: 0, dy: topOfRegMedRects - 10)
                }
            }
            
            let medRectPath = UIBezierPath(roundedRect: shiftedRect, cornerRadius: cornerRadius)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[count].setFill()
            medRectPath.fill()
            medRectPath.stroke()
//            topOfRegMedRects = shiftedRect.origin.y - shiftedRect.height - 5
            count += 1
        }
        
//        regBarsPath.lineWidth = 1.0
//        prnBarsPath.lineWidth = 1.0
//        
//        colorScheme.medBarGreen.setFill()
//        regBarsPath.fill()
// 
//        prnBarsPath.stroke()
//        colorScheme.medBarGreen.setFill()
//        prnBarsPath.fill()
}

}
