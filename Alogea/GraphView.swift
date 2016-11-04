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
    @IBOutlet weak var graphContainerView: GraphContainerView!
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
    var refreshPointsFlag: Bool = true
    
    var timeLinePoints: [CGPoint]!
    var timeLineLabels = [UILabel]() // number is calculated and adapted upwards (only) in drawTimeLine() function


    // var rotationObserver: NotificationCenter!
    
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
        timeLinePoints = [CGPoint]()
        
        
        // *** Debug
        if helper.selectedScoreEventsFRC.fetchedObjects?.count == 0 {
            eventsDataController.createExampleEvents()
            helper.printSelectedScoreEventDates()
        }
        // ***

        // rotationObserver = NotificationCenter.default
        
        // rotationObserver.addObserver(self, selector: #selector(deviceRotation(notification:)), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)

    }
    
    /*
    deinit {
        NotificationCenter.default.removeObserver(rotationObserver)
    }
     */
    
    override func draw(_ rect: CGRect) {

        drawTimeLine()
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
        clipPath.addLine(to: CGPoint(x:graphPoints[graphPoints.count - 1].x, y: bounds.maxY - helper.timeLineSpace()))
        clipPath.addLine(to: CGPoint(x: graphPoints[0].x, y: bounds.maxY - helper.timeLineSpace()))
        clipPath.close()
        clipPath.addClip()
        
        let gradientStartPoint = CGPoint(x: 0, y: highestGraphPoint)
        let gradientEndPoint = CGPoint(x: 0, y: bounds.maxY - helper.timeLineSpace())
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
    
    func drawTimeLine() {
        
//        var minTimeLineDate = Date()
        let dataArray = TimeLineHelper.timeLineArray(timeSpan: displayedTimeSpan, viewWidth: frame.width, minEventDate: minGraphDate, minDisplayDate: minDisplayDate)
//        (_,_,minTimeLineDate) = dataArray[0] // timeLineSet as building block for tlArray contains in its last
        
        let timeLineTicks = UIBezierPath()
        let timeLineY = bounds.maxY - helper.timeLineSpace()
//        print("graphView timeLineSpace = \(timeLineSpace)")
//        print("graphView lowerLine y = \(timeLineY)")
        for label in timeLineLabels {
            label.text = ""
        }
        var count = 0
        for tickSet in dataArray {
            
            timeLineTicks.move(to: CGPoint(x: tickSet.tickPosition, y: timeLineY))
            timeLineTicks.addLine(to: CGPoint(x: tickSet.tickPosition, y: timeLineY + helper.timeLineTickLength))
            
            if count >= timeLineLabels.count { addTimeLineLabel() }
            
            let label = timeLineLabels[count]
            label.text = tickSet.tickLabelText
            label.sizeToFit()
            label.frame.origin = CGPoint(
                x:  tickSet.tickPosition - timeLineLabels[count].frame.width / 2,
                y: timeLineY + helper.timeLineTickLength + 2
            )
            if label.superview != self {
                self.addSubview(timeLineLabels[count])
            }
            count += 1
        }
        
        colorScheme.lightGray.setStroke()
        timeLineTicks.lineWidth = 1.0
        timeLineTicks.stroke()
        
        
    }
    
    func addTimeLineLabel() {
        // called from drawTimeLine() in case more labels are needed, usually when zooming in; these can increase up to ca. 1500!!
        // all labels for later zoom out are deleted in the MasterView.timeSegmentChosen() and GV2.zoompinch() functions
        let label: UILabel = {
            let aLabel = UILabel()
            aLabel.text = ""
            aLabel.font = UIFont(name: "AvenirNext-Regular", size: 12.0)
            aLabel.textColor = colorScheme.lightGray
            aLabel.sizeToFit()
            aLabel.frame.origin = CGPoint(
                x:  0.0,
                y: 0.0
            )
            return aLabel
        }()
        self.addSubview(label)
        timeLineLabels.append(label)
    }
    
    func removeTimeLineLabels() {
        
        for label in timeLineLabels {
            label.removeFromSuperview()
        }
        timeLineLabels = [UILabel]()
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
    
    /*
    func deviceRotation(notification: Notification) {
        
        setNeedsDisplay() //  doesn't work
        // also need to re-position UILabels in GraphContainer - this needs an observer as well
    }
    */
    
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
        graphContainerView.updateBottomLabel()
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
        
        minDisplayDate = minDisplayDate.addingTimeInterval(timeChangeLeft)
        maxDisplayDate = maxDisplayDate.addingTimeInterval(timeChangeRight)
        displayedTimeSpan = maxDisplayDate.timeIntervalSince(minDisplayDate)
        
        if recognizer.state == .began {
            mainViewController.displayTimeSegmentedController.selectedSegmentIndex = UISegmentedControlNoSegment
        } else if recognizer.state == .ended {
            graphContainerView.updateLabels()
            if recognizer.scale > 1 {
                // there may be far too many (up to 1500) timeLineLabels from a previous zoom in; remove these and calculate anew the required number
                removeTimeLineLabels()
            }
        }
        setNeedsDisplay()
        graphContainerView.updateBottomLabel()
    }

}
