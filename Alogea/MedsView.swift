//
//  MedsView.swift
//  Alogea
//
//  Created by mikeMBP on 27/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

let medBarHeight: CGFloat = 12.0 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height

class MedsView: UIView {
    
    var graphView: GraphView!
    var helper: GraphViewHelper!
    var medController: MedicationController!
    
    var regMedsFRC: NSFetchedResultsController<DrugEpisode> {
        return MedicationController.sharedInstance().regMedsFRC
    }
    
    var prnMedsFRC: NSFetchedResultsController<Event> {
        return EventsDataController.sharedInstance().medicineEventsFRC
    }
    
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
        
        let scale = graphView.maxDisplayDate.timeIntervalSince(graphView.minDisplayDate) / TimeInterval(graphView.frame.width)
        let cornerRadius: CGFloat = 8.0 / 2
        let fontSize: CGFloat = 11 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
        
        let verticalOffset = bounds.maxY - helper.timeLineSpace()
        var topOfRegMedRects = verticalOffset // to find vertical lowest position for prnMedRect
        
        UIColor.white.setStroke()
        
        var rectArray = [CGRect]()
        
        var count = 0
        for medicine in regMedsFRC.fetchedObjects! {
            var medRect = medicine.medRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medicine.startDate as! Date, scale: scale), dy: verticalOffset)
            rectArray.append(medRect)
            
            for i in 0..<count {
                if medRect.intersects(rectArray[i]) {
                    medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                    if medRect.minY < topOfRegMedRects {
                        // ensure prnMedRect are positoned higher than regMedRects
                        topOfRegMedRects = medRect.minY - medBarHeight - 2
                    }
                }
            }

            let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[count].setFill()
            medRectPath.fill()
            medRectPath.stroke()
            let medName = medicine.name as NSString?
            medName?.draw(in: medRect.offsetBy(dx: 5, dy: -1), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
            count += 1
        }
        
        rectArray = [CGRect]()
        count = 0
        for medEvent in prnMedsFRC.fetchedObjects! {
            var medRect = medEvent.eventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medEvent.date as! Date, scale: scale), dy: topOfRegMedRects)
            
            // ensure medRects don't overlap, otherwise shift rect up by 5
            rectArray.append(medRect)
            for i in 0..<count {
                if medRect.intersects(rectArray[i]) {
                    medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                }
            }
            
            let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[count].setFill()
            medRectPath.fill()
            medRectPath.stroke()
            let medName = medEvent.name as NSString?
            medName?.draw(in: medRect.offsetBy(dx: 3, dy: -1), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
            count += 1
        }
        
    }
    
    
    private func leftXPosition(startDate: Date, scale: TimeInterval) -> CGFloat {
        
        return CGFloat(startDate.timeIntervalSince(graphView.minDisplayDate) / scale)
    }

}
