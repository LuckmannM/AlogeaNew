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
    @IBOutlet var zoomRecognizer: UIPinchGestureRecognizer!
    
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
    var refreshPointsFlag: Bool = true

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
    
    deinit {
        NotificationCenter.default.removeObserver(rotationObserver)
    }
    
    override func draw(_ rect: CGRect) {

        if refreshPointsFlag {
            graphPoints = helper.calculateGraphPoints(forFrame: frame, withDisplayedTimeSpan: displayedTimeSpan, withMinDate: minDisplayDate)
        }
        guard graphPoints.count > 0  else { return }
        drawLineGraph()
        refreshPointsFlag = true
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
    
    func shiftGraphPoints(by: CGFloat) {
        
        var i = 0
        for _ in graphPoints {
            graphPoints[i].offSetX(by: by)
            i += 1
        }
        refreshPointsFlag = false
        setNeedsDisplay()
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
        let now = Date()
        
        if now.compare(maxDisplayDate.addingTimeInterval(timeShift)) == .orderedAscending {
            // end shift as current date on right side has been reached
            return
        }
        else if minGraphDate.compare(minDisplayDate.addingTimeInterval(timeShift)) == .orderedDescending {
            // end shift as earliest timeLine date on left side has been reached
            return
        }
        
        maxDisplayDate = maxDisplayDate.addingTimeInterval(timeShift)
        minDisplayDate = minDisplayDate.addingTimeInterval(timeShift)
        shiftGraphPoints(by: shift.x)
        recogniser.setTranslation(CGPoint(x: 0, y: 0), in:self)

    }
    
    @IBAction func zoom(recognizer: UIPinchGestureRecognizer) {
        
        /*
         starting clipViewScale = 1
         0 < 1 = zoom out = moving fingers closer together
         > 1 = zoom in = moving fingers apart = zoom in / magnify
         */
        
        let newDTS = displayedTimeSpan / TimeInterval(sqrt(recognizer.scale))
        if newDTS <= 86400 || newDTS > graphTimeSpan { return }
        let dTSChange = (newDTS - displayedTimeSpan) / 25 // 25 is make zoom slower and more controlled
        
        var timeChangeRight = dTSChange / 2
        var timeChangeLeft = -dTSChange / 2
        let now = Date()
        
        if now.compare(maxDisplayDate.addingTimeInterval(dTSChange / 2)) == .orderedAscending {
            timeChangeRight = now.timeIntervalSince(maxDisplayDate)
            timeChangeLeft = -(dTSChange - timeChangeRight)
        }
        //        debugDisplayLabel.text = "\(displayedTimeSpan / 86400) days"
        //        debugDisplayLabel.sizeToFit()
        
        minDisplayDate = minDisplayDate.addingTimeInterval(timeChangeLeft)
        maxDisplayDate = maxDisplayDate.addingTimeInterval(timeChangeRight)
        displayedTimeSpan = maxDisplayDate.timeIntervalSince(minDisplayDate)
        
        setNeedsDisplay()
    }

}
