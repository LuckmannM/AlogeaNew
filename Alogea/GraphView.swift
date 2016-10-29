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
    
    var helper: GraphViewHelper!
    
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
    
    var displayedTimeSpan: TimeInterval!
    var minDisplayDate: Date!
    var maxDisplayDate: Date!
    
    var timeLineSpace: CGFloat {
        return helper.timeLineLabelHeight + helper.timeLineTickLength + 5
    }

    // MARK: - methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.helper = GraphViewHelper(graphView: self)
        self.graphPoints = [CGPoint]()
        self.eventsDataController.graphView = self
        
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

        
        drawHorizontalLines()
        
        graphPoints = calculateGraphPoints()
        
        guard graphPoints.count > 0  else { return }
        drawLineGraph()
    }
    
    func drawHorizontalLines() {
        let xStart: CGFloat = bounds.origin.x
        let xEnd: CGFloat = bounds.maxX
        //        print("drawLines from \(xStart) to \(xEnd)")
        
        let upperLineY = bounds.minY + 1.0
        let lowerLineY = bounds.maxY - timeLineSpace
        let midLineY = (upperLineY + lowerLineY) / 2 + 0.5
        
        
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: xStart, y: upperLineY))
        linePath.addLine(to: CGPoint(x: xEnd, y: upperLineY))
        
        linePath.move(to: CGPoint(x: xStart, y: midLineY))
        linePath.addLine(to: CGPoint(x: xEnd, y: midLineY))
        
        linePath.move(to: CGPoint(x: xStart, y:lowerLineY))
        linePath.addLine(to: CGPoint(x: xEnd, y: lowerLineY))
        
        
        colorScheme.lightGray.withAlphaComponent(0.75).setStroke()
        linePath.lineWidth = helper.lineGraphLineWidth
        linePath.stroke()
        
    }
    
    func drawLineGraph() {
        
        let lineContext = UIGraphicsGetCurrentContext()
        let graphPath = UIBezierPath()
        var highestGraphPoint: CGFloat = frame.height

        graphPath.move(to: graphPoints[0])
        for k in 1..<graphPoints.count {
            graphPath.addLine(to: graphPoints[k])
            if graphPoints[k].y < highestGraphPoint { highestGraphPoint = graphPoints[k].y }
        }
        graphPath.lineWidth = helper.lineGraphLineWidth
        colorScheme.lightGray.setStroke()
        graphPath.stroke()
        
        // create clipPath for gradient under lineGraph
        lineContext!.saveGState()
        let clipPath = graphPath.copy() as! UIBezierPath
        clipPath.addLine(to: CGPoint(x:graphPoints[graphPoints.count - 1].x, y: bounds.maxY - timeLineSpace))
        clipPath.addLine(to: CGPoint(x: graphPoints[0].x, y: bounds.maxY - timeLineSpace))
        clipPath.close()
        clipPath.addClip()
        
        let gradientStartPoint = CGPoint(x: 0, y: highestGraphPoint)
        let gradientEndPoint = CGPoint(x: 0, y: bounds.maxY - timeLineSpace)
        lineContext!.drawLinearGradient(helper.lineGraphGradient(), start: gradientStartPoint, end: gradientEndPoint, options: CGGradientDrawingOptions.drawsAfterEndLocation)
        lineContext!.restoreGState()
        
        // draw small circles
        helper.lineCircleFillColor.setFill()
        for i in 0..<graphPoints.count {
            let circlePoint = CGPoint(x: graphPoints[i].x - helper.lineGraphCircleRadius, y: graphPoints[i].y - helper.lineGraphCircleRadius)
            let circle = UIBezierPath(ovalIn: CGRect(origin: circlePoint, size: CGSize(width: helper.lineGraphCircleRadius * 2, height: helper.lineGraphCircleRadius * 2)))
            circle.lineWidth = helper.lineGraphCircleLineWidth
            circle.stroke()
            circle.fill()
        }
    }

    func calculateGraphPoints() -> [CGPoint] {
        
        var points = [CGPoint]()
        var maxVAS = CGFloat()

        guard let scoreEventsData = eventsDataController.graphData() else {
            return points
        }
        
        if recordTypesController.returnMaxVAS(forType: eventsDataController.selectedScore) == nil {
            print("no maxValue found for selected scoreEventType \(eventsDataController.selectedScore)")
            maxVAS = 10.0
        } else {
            maxVAS = CGFloat(recordTypesController.returnMaxVAS(forType: eventsDataController.selectedScore)!)
        }

        let timePerWidth = CGFloat(graphTimeSpan) / frame.width

        for eventData in scoreEventsData {
            let xCoordinate = CGFloat(TimeInterval(eventData.date .timeIntervalSince(minGraphDate))) / timePerWidth
            let yCoordinate = (frame.height - timeLineSpace) * eventData.score / maxVAS
            let newPoint = CGPoint(x: xCoordinate, y: yCoordinate)
            points.append(newPoint)
        }
        
        return points
    }

}
