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
let eventDiamondSize: CGFloat = 15.0 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height

class MedsView: UIView {
    
    let cornerRadius: CGFloat = 8.0 / 2
    let fontSize: CGFloat = 11 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height

    
    var graphView: GraphView!
    var helper: GraphViewHelper!
    var medController: MedicationController!
    
    var regMedsFRC: NSFetchedResultsController<DrugEpisode> {
        return MedicationController.sharedInstance().regMedsFRC
    }
    
    var prnMedsFRC: NSFetchedResultsController<Event> {
        return EventsDataController.sharedInstance().medicineEventsFRC
    }
    
    var diaryEventsFRC: NSFetchedResultsController<Event> {
        return EventsDataController.sharedInstance().nonScoreEventsFRC
    }
    
    var symbolArrays = [[CGRect]]()
    var count = 0
    var colorArrayCount = 0
    let numberOfColors = ColorScheme.sharedInstance().barColors.count


    
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
        
        UIColor.white.setStroke()
        symbolArrays.removeAll()

        let scale = graphView.maxDisplayDate.timeIntervalSince(graphView.minDisplayDate) / TimeInterval(graphView.frame.width)
        
        let topOfRegMedRects = drawRegularMeds(scale: scale, verticalOffset: bounds.maxY - helper.timeLineSpace())
        
        let topOfPrnMedRects = drawPrnMeds(scale: scale, verticalOffset: topOfRegMedRects)
        
        drawNonScoreEvents(scale: scale, verticalOffset: topOfPrnMedRects)
        
        // symbol Arrays contains all med and eventRects for use in touch events
        
    }
    
    private func drawRegularMeds(scale: TimeInterval, verticalOffset: CGFloat) -> CGFloat {
        
        var rectArray = [CGRect]()
        var topOfRect = verticalOffset
        count = 0
        colorArrayCount = 0
        for medicine in regMedsFRC.fetchedObjects! {
            var medRect = medicine.medRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medicine.startDate as! Date, scale: scale), dy: verticalOffset)
            
            for i in 0..<count {
                if medRect.intersects(rectArray[i]) {
                    medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                    if medRect.minY < topOfRect {
                        // ensure prnMedRect are positoned higher than regMedRects
                        topOfRect = medRect.minY - medBarHeight - 2
                    }
                }
            }
            rectArray.append(medRect)
            
            let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
            medRectPath.fill()
            medRectPath.stroke()
            let medName = medicine.name as NSString?
            medName?.draw(in: medRect.offsetBy(dx: 5, dy: -1), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
            count += 1
            colorArrayCount += 1
            if colorArrayCount == numberOfColors {
                colorArrayCount = 0
            }
        }
        symbolArrays.append(rectArray)
        return topOfRect
    }
    
    private func drawPrnMeds(scale: TimeInterval, verticalOffset: CGFloat) -> CGFloat {
        
        var topOfRect = verticalOffset
        var rectArray = [CGRect]()
        
        count = 0
        colorArrayCount = 0
        var sectionCount = 0
        var eventCount = 0
        
        for section in prnMedsFRC.sections! {
            for index in 0..<section.numberOfObjects {
                let medEvent = prnMedsFRC.object(at: IndexPath(item: index, section: sectionCount))
                var medRect = medEvent.medEventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medEvent.date as! Date, scale: scale), dy: verticalOffset)
                for i in 0..<eventCount {
                    if medRect.intersects(rectArray[i]) {
                        medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                        if medRect.minY < topOfRect {
                            // ensure prnMedRect are positoned higher than regMedRects
                            topOfRect = medRect.minY - medBarHeight - 2
                        }
                    }
                }
                rectArray.append(medRect)
                
                let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
                medRectPath.lineWidth = 1.0
                ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
                medRectPath.fill()
                medRectPath.stroke()
                
                var medName = NSString()
                if medRect.width == medBarHeight {
                    medName = (medEvent.name! as NSString).substring(to: 1) as NSString
                } else {
                    medName = medEvent.name! as NSString
                }
                medName.draw(in: medRect.offsetBy(dx: 3, dy: -1), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
                
                eventCount += 1
            }
            colorArrayCount += 1
            if colorArrayCount == numberOfColors {
                colorArrayCount = 0
            }
            sectionCount += 1
        }
        symbolArrays.append(rectArray)
        return topOfRect
    }
    
    private func drawNonScoreEvents(scale: TimeInterval, verticalOffset: CGFloat)  {
        
        count = 0
        var rectArray = [CGRect]()
        
        var sectionCount = 0
        var eventCount = 0
        colorArrayCount = 0
        
        for section in diaryEventsFRC.sections! {
            for index in 0..<section.numberOfObjects {
                let event = diaryEventsFRC.object(at: IndexPath(item: index, section: sectionCount))
                var eventRect = event.nonScoreEventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: event.date as! Date, scale: scale), dy: verticalOffset)
                for i in 0..<eventCount {
                    if eventRect.intersects(rectArray[i]) {
                        eventRect = eventRect.offsetBy(dx: 0, dy: -eventDiamondSize - 2)
                    }
                }
                rectArray.append(eventRect)
                
                let diamondPath = UIBezierPath()
                diamondPath.move(to: CGPoint(x:eventRect.midX, y: eventRect.minY))
                diamondPath.addLine(to: CGPoint(x:eventRect.minX, y: eventRect.midY))
                diamondPath.addLine(to: CGPoint(x:eventRect.midX, y: eventRect.maxY))
                diamondPath.addLine(to: CGPoint(x:eventRect.maxX, y: eventRect.midY))
                diamondPath.addLine(to: CGPoint(x:eventRect.midX, y: eventRect.minY))
                
                diamondPath.lineWidth = 1.0
                ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
                diamondPath.fill()
                diamondPath.stroke()
                
                let eventName = (event.name as NSString?)?.substring(to: 1)
                eventName?.draw(in: eventRect.offsetBy(dx: 4, dy: 0), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
                
                eventCount += 1
            }
            colorArrayCount += 1
            if colorArrayCount == numberOfColors {
                colorArrayCount = 0
            }
            sectionCount += 1
        }
        symbolArrays.append(rectArray)
    }
    
    private func leftXPosition(startDate: Date, scale: TimeInterval) -> CGFloat {
        
        return CGFloat(startDate.timeIntervalSince(graphView.minDisplayDate) / scale)
    }

}
