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
    
    @IBOutlet weak var mainViewController: MainViewController!
    @IBOutlet weak var clipView: ClipView!
    @IBOutlet var leftFrameConstraint: NSLayoutConstraint!
    @IBOutlet var rightFrameConstraint: NSLayoutConstraint!
    @IBOutlet var dragRecognizer: UIPanGestureRecognizer!
    
    let eventsDataController = EventsDataController.sharedInstance()
    let colorScheme = ColorScheme.sharedInstance()
    var graphPoints: [CGPoint]!
    
    var helper: GraphViewHelper!
    
    var maxGraphDate: Date {
        return Date()
    }
    var minGraphDate: Date {
        if helper.selectedScoreEventMinMaxDates != nil {
            return (helper.selectedScoreEventMinMaxDates![0])
        } else {
            mainViewController.displayTimeSegmentedController.selectedSegmentIndex = 0
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

    var rotationObserver: NotificationCenter!
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
        if helper.selectedScoreEventsTimeSpan < (24 * 3600) {
            mainViewController.displayTimeSegmentedController.selectedSegmentIndex = 0
            displayedTimeSpan = 24 * 3600
        } else {
            displayedTimeSpan = helper.selectedScoreMinDateToNow // set initial dTS to minScoreEventDate to now
            minDisplayDate = maxDisplayDate.addingTimeInterval(-displayedTimeSpan)
        }
        
        graphPoints = [CGPoint]()
        
        
        // *** Debug
        if helper.selectedScoreEventsFRC.fetchedObjects?.count == 0 {
            eventsDataController.createExampleEvents()
            helper.printSelectedScoreEventDates()
        }
        // ***

        rotationObserver = NotificationCenter.default
        
        rotationObserver.addObserver(self, selector: #selector(deviceRotation(notification:)), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)

    }
    
    override func draw(_ rect: CGRect) {

        
//        drawHorizontalLines()
        
        graphPoints = calculateGraphPoints()
        
        guard graphPoints.count > 0  else { return }
        drawLineGraph()
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

        guard let scoreEventsData = helper.graphData() else {
            return points
        }
        
        if recordTypesController.returnMaxVAS(forType: helper.selectedScore) == nil {
            print("no maxValue found for selected scoreEventType \(helper.selectedScore)")
            maxVAS = 10.0
        } else {
            maxVAS = CGFloat(recordTypesController.returnMaxVAS(forType: helper.selectedScore)!)
        }

        let timePerWidth = CGFloat(displayedTimeSpan) / frame.width

        for eventData in scoreEventsData {
            let xCoordinate = CGFloat(TimeInterval(eventData.date .timeIntervalSince(minDisplayDate))) / timePerWidth
            let yCoordinate = (frame.height - timeLineSpace) * (maxVAS - eventData.score) / maxVAS
            let newPoint = CGPoint(x: xCoordinate, y: yCoordinate)
            points.append(newPoint)
        }
        
        return points
    }
    
    func changeDisplayedInterval(toInterval: TimeInterval? = nil, toDates:[Date]? = nil) {
        
        guard toInterval != nil || toDates != nil else {
            return
        }
        
        var newDisplayInterval: TimeInterval?
        
        if toInterval != nil {
            newDisplayInterval = toInterval
            if newDisplayInterval! < (24 * 3600) {
                newDisplayInterval = 24 * 3600
            }
            displayedTimeSpan = newDisplayInterval
            maxDisplayDate = Date()
            minDisplayDate = maxDisplayDate.addingTimeInterval(-displayedTimeSpan)
        } else {
            minDisplayDate = toDates![0]
            maxDisplayDate = toDates![1]
            displayedTimeSpan = maxDisplayDate.timeIntervalSince(minDisplayDate)
        }
        
        
        setNeedsDisplay()
        print("displayedTimeSpan changed to \(displayedTimeSpan/(24*3600)) days")
        print("set minDisplayDate to \(minDisplayDate)")
    }
    
    func deviceRotation(notification: Notification) {
        
        setNeedsDisplay() //  doesn't work
        // also need to re-position UILabels in GraphContainer - this needs an observer as well
    }
    
    @IBAction func drag(recogniser: UIPanGestureRecognizer) {
        
        let shift: CGPoint = recogniser.translation(in: self)
        // dragging view to the RIGHT side = positive shift = DECREASING min/maxDisplayDates
        // dragging view to the LEFT side = negative shift = INCREASING min/maxDisplayDates
        
        let timeShift = TimeInterval(shift.x * CGFloat(-displayedTimeSpan)/frame.width)
        print("drag, timeShift = \(timeShift/3600) hours")
        let now = NSDate()
        if now.earlierDate((maxDisplayDate as NSDate).addingTimeInterval(timeShift) as Date) == now as Date {
            
            // end shift as current date on right side has been reached
            return
        } else if (minDisplayDate as NSDate).laterDate(minDisplayDate.addingTimeInterval(timeShift)) == minGraphDate {
            
            // end shift as earliest timeLine date on left side has been reached
            print("over left limit")
            print("minTimeLineDate = \(minDisplayDate)")
            print("minDisplayDate with graphSift would be  = \(minDisplayDate.addingTimeInterval(timeShift)))")
            return
        }
        
        let newMaxDisplayDate = maxDisplayDate.addingTimeInterval(timeShift)
        let newMinDisplayDate = minDisplayDate.addingTimeInterval(timeShift)
        print("new minDD is \(newMinDisplayDate)")
        
        changeDisplayedInterval(toDates: [newMinDisplayDate, newMaxDisplayDate])
        recogniser.setTranslation(CGPoint(x: 0, y: 0), in:self)

    }

}
