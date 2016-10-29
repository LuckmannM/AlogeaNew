//
//  GraphView.swift
//  Alogea
//
//  Created by mikeMBP on 23/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import Foundation

class GraphView: UIView {
    
    let eventsDataController = EventsDataController.sharedInstance()
    let colorScheme = ColorScheme.sharedInstance()
    var graphPoints: [CGPoint]!
    
    var displayedTimeSpan: TimeInterval!
    var minDisplayDate: Date!
    var maxDisplayDate: Date!
    
    var maxGraphDate: Date {
        return Date()
    }
    var minGraphDate: Date {
        if eventsDataController.selectedScoreEventMinMaxDates != nil {
            return (eventsDataController.selectedScoreEventMinMaxDates![0])
        } else {
            return maxGraphDate.addingTimeInterval(-24 * 3600)
        }
    }
    var graphTimeSpan: TimeInterval {
        return maxGraphDate.timeIntervalSince(minGraphDate)
    }
    
    let lineGraphLineWidth: CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        maxDisplayDate = Date()
        minDisplayDate = maxDisplayDate.addingTimeInterval(-24 * 3600)
        if eventsDataController.selectedScoreEventsTimeSpan < (24 * 3600) {
            displayedTimeSpan = 24 * 3600
        } else {
            displayedTimeSpan = eventsDataController.selectedScoreEventsTimeSpan // set initial dTS to min-maxScoreEventDates
        }
        
        graphPoints = [CGPoint]()
        
        
        // *** Debug
        if eventsDataController.selectedScoreEventsFRC.fetchedObjects?.count == 0 {
            eventsDataController.createExampleEvents()
            eventsDataController.printSelectedScoreEventDates()
        }
        // ***
        
    }
    

    override func draw(_ rect: CGRect) {
        // Drawing code

//        let lineContext = UIGraphicsGetCurrentContext()
        let graphPath = UIBezierPath()
        
        graphPoints = calculateGraphPoints()
        
        guard graphPoints.count > 0  else { return }
        
        //create lineGraph
        graphPath.move(to: graphPoints[0])
        for k in 1..<graphPoints.count {
            graphPath.addLine(to: graphPoints[k])
        }
        graphPath.lineWidth = lineGraphLineWidth
        UIColor.white.setStroke()
        graphPath.stroke()
        
    }
    
    func calculateGraphPoints() -> [CGPoint] {
        
        var points = [CGPoint]()
        var maxVAS = CGFloat()
        var highPoint = CGFloat()
        
        guard let scoreEventsData = eventsDataController.graphData() else {
            return points
        }
        
        if recordTypesController.returnMaxVAS(forType: eventsDataController.selectedScore) == nil {
            print("no maxValue found for selected scoreEventType \(eventsDataController.selectedScore)")
            maxVAS = 10.0
        } else {
            maxVAS = CGFloat(recordTypesController.returnMaxVAS(forType: eventsDataController.selectedScore)!)
        }

        let timePerWidth = CGFloat(displayedTimeSpan) / frame.width

        for eventData in scoreEventsData {
            let xCoordinate = CGFloat(TimeInterval(eventData.date .timeIntervalSince(minGraphDate))) / timePerWidth
            let yCoordinate = frame.height * eventData.score / maxVAS
            let newPoint = CGPoint(x: xCoordinate, y: yCoordinate)
            points.append(newPoint)
        }
        
        return points
    }

}
