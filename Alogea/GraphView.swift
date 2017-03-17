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
    @IBOutlet var medViewTapGesture: UITapGestureRecognizer!

    
    let eventsDataController = EventsDataController.sharedInstance()
    let colorScheme = ColorScheme.sharedInstance()
    var graphPoints: [CGPoint]!
    
    var helper: GraphViewHelper!
    var medsView: MedsView!
    
    var maxGraphDate: Date {
        return Date()
    }
    var minGraphDate: Date {
        if helper.allEventsMinMaxDates != nil {
            return (helper.allEventsMinMaxDates![0])
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
    
    var graphIsStatType: Bool {
        return UserDefaults.standard.bool(forKey: "GraphIsStat")
    }
    
    var timeLinePoints: [CGPoint]!
    var timeLineLabels = [UILabel]() // number is calculated and adapted upwards (only) in drawTimeLine() function

    // MARK: - methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.helper = GraphViewHelper(graphView: self)
        self.graphPoints = [CGPoint]()
        self.eventsDataController.graphView = self

        
        maxDisplayDate = Date()
        minDisplayDate = maxDisplayDate.addingTimeInterval(-24 * 3600)
        if helper.allGraphEventsTimeSpan < (24 * 3600) {
            displayedTimeSpan = 24 * 3600
        } else {
            displayedTimeSpan = TimeInterval(7 * 24 * 3600) // one week default
            // for timeSpan including all stored events use below instead
            // displayedTimeSpan = helper.selectedScoreMinDateToNow
            minDisplayDate = maxDisplayDate.addingTimeInterval(-displayedTimeSpan)
        }
        
        graphPoints = [CGPoint]()
        timeLinePoints = [CGPoint]()
        
        self.medsView = MedsView(graphView: self)
        self.addSubview(medsView)
        //self.insertSubview(medsView, belowSubview: self)

    }
    
    override func draw(_ rect: CGRect) {
        
        drawTimeLine()
        if refreshPointsFlag {
            graphPoints = helper.calculateGraphPoints(forFrame: frame, withDisplayedTimeSpan: displayedTimeSpan, withMinDate: minDisplayDate)
        }
        
        medsView.frame = bounds
        medsView.setNeedsDisplay()
        
//        guard graphPoints.count > 0  else {
//            return
//        }
        
        if  graphIsStatType {
            //drawBarGraph()
            drawStats()
        } else if graphPoints.count > 0 {
            drawLineGraph()
        }
        
       // drawStats()
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
    
    
    // FIXME: scoreType match stats type
    
    func drawStats() {
        
        guard let episodeStats = StatisticsController.sharedInstance().returnEpisodeStats(forScoreType: helper.selectedScore) else {

            let textwidth: CGFloat = 250
            let titleRect = CGRect(x: frame.midX - textwidth / 2.0, y: frame.midY - 15, width: textwidth, height: 30)
            let text: NSString = "not enough scores to analyse"
            text.draw(in: titleRect, withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: 18.0)!,NSForegroundColorAttributeName: UIColor.white])
            
            return
        }
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            return formatter
        }()

        
        let displayScale = CGFloat(displayedTimeSpan) / frame.width
        let bottomY = bounds.maxY - helper.timeLineSpace()
        let topY: CGFloat = 5
        var maxVAS: Double = 10.0
        
        if RecordTypesController.sharedInstance().returnMaxVAS(forType: helper.selectedScore) != nil {
            maxVAS = RecordTypesController.sharedInstance().returnMaxVAS(forType: helper.selectedScore)!
        }
        
        let episodeBars = UIBezierPath()
        let meanBars = UIBezierPath()
        let stdErrRects = UIBezierPath()
        var maxTextWidth: CGFloat!
        
        for stat in episodeStats {
            //if stat.scoreTypeName == helper.selectedScore { //  this needs testing to ensure that the episodeStats match the displayed score type
                let timeSinceMinDateForStart = stat.startDate.timeIntervalSince(minDisplayDate)
                let timeSinceMinDateForEnd = stat.endDate.timeIntervalSince(minDisplayDate)
                
                // vertical episode bars
                let episodeStartX = CGFloat(timeSinceMinDateForStart) / displayScale
                episodeBars.move(to: CGPoint(x: episodeStartX, y: bottomY))
                episodeBars.addLine(to: CGPoint(x: episodeStartX, y: topY))
                
                // horizontal mean and SE bars if >1 score
                if stat.numberOfScores > 0 {
                    let meanY = (frame.height - helper.timeLineSpace()) * CGFloat((maxVAS - stat.mean) / maxVAS)
                    let episodeEndX = CGFloat(timeSinceMinDateForEnd) / displayScale
                    meanBars.move(to: CGPoint(x: episodeStartX, y: meanY))
                    meanBars.addLine(to: CGPoint(x: episodeEndX, y: meanY))
                    
                    maxTextWidth = episodeEndX - episodeStartX
                    if maxTextWidth > 60 {
                        maxTextWidth = 30
                    }
                    
                    let meanBarTextBox = CGRect(
                        x: episodeStartX + (episodeEndX - episodeStartX - maxTextWidth) / 2,
                        y: meanY - 20,
                        width: maxTextWidth,
                        height: 18
                    )
                    
                    let meanText = (numberFormatter.string(from: stat.mean as NSNumber) ?? "")
                    meanText.draw(in: meanBarTextBox.insetBy(dx: 2, dy: 0), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 16.0)!,NSForegroundColorAttributeName: UIColor.white])
                    /*
                    let seUpperY = (frame.height - helper.timeLineSpace()) * CGFloat((maxVAS - stat.mean - 1.96 * stat.stdError) / maxVAS)
                    let seLowerY = (frame.height - helper.timeLineSpace()) * CGFloat((maxVAS - stat.mean + 1.96 * stat.stdError) / maxVAS)
                    
                    let rect = CGRect(x: episodeStartX, y: seUpperY, width: (episodeEndX - episodeStartX), height: seLowerY - seUpperY)
                    stdErrRects.append(UIBezierPath(rect: rect))
                    */
                    if stat.compareToPrevious != nil {
                        displayMeanChange(change: stat.compareToPrevious!, xPos: episodeStartX, xWidth: episodeEndX - episodeStartX, meanYPos: meanY)
                    }
                    
                    if stat.moreThan5TimePct > 0 && stat.lessThan3TimePct > 0 {
                        drawStatText(upperNumber: stat.moreThan5TimePct, lowerNumber: stat.lessThan3TimePct, xPos: episodeStartX, episodeWidth: episodeEndX - episodeStartX)
                    }
                }
            }
            colorScheme.pearlWhite.setStroke()
            episodeBars.lineWidth = 1.0
            episodeBars.stroke()
            
            meanBars.lineWidth = 3.0
            meanBars.stroke()
            
            colorScheme.pearlWhite04.setFill()
            stdErrRects.fill()
       // }
    }
    
    func displayMeanChange(change: Double, xPos: CGFloat, xWidth: CGFloat, meanYPos: CGFloat) {
        
        print("change: \(change)")
        
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            return formatter
        }()

        let fromMeanBar: CGFloat = change > 0 ? meanYPos - 36 : meanYPos + 2
        let boxWidth: CGFloat = xWidth > 30 ? 30 : xWidth
        
        var arrowBoxRect = CGRect(x: xPos + (xWidth - boxWidth) / 2, y: fromMeanBar, width: boxWidth, height: 16)
        
        // if mean is close to 10 or 0 offSet arrow to avoid overspilling out of bounds
        if arrowBoxRect.minY - 10 < 0 {
            arrowBoxRect = arrowBoxRect.offsetBy(dx: 0, dy: 48)
        } else if (arrowBoxRect.maxY + 10) > (bounds.maxY - helper.timeLineSpace()) {
            arrowBoxRect = arrowBoxRect.offsetBy(dx: 0, dy: -48)
        }
        
        let boxPath = UIBezierPath(roundedRect: arrowBoxRect, cornerRadius: 0)
        
        if change > 0 {
            colorScheme.medBarRed.setFill()
            boxPath.move(to: arrowBoxRect.origin)
            boxPath.addLine(to: CGPoint(x:arrowBoxRect.origin.x + arrowBoxRect.width / 2, y:arrowBoxRect.minY - 10))
            boxPath.addLine(to: CGPoint(x:arrowBoxRect.maxX , y:arrowBoxRect.origin.y))
        } else {
            colorScheme.medBarGreen.setFill()
            boxPath.move(to: CGPoint(x:arrowBoxRect.origin.x, y:arrowBoxRect.maxY))
            boxPath.addLine(to: CGPoint(x:arrowBoxRect.origin.x + arrowBoxRect.width / 2, y:arrowBoxRect.maxY + 10))
            boxPath.addLine(to: CGPoint(x:arrowBoxRect.maxX , y:arrowBoxRect.maxY))
        }
        
        
        //colorScheme.pearlWhite.setStroke()
        boxPath.fill()
        
        
        var text = String()
        if (abs(change) < 100.0) {
            text = (numberFormatter.string(from: change as NSNumber) ?? "") + "%"
        } else {
            text = ">99%"
        }
        text.draw(in: arrowBoxRect.insetBy(dx: 2, dy: 0), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: 11.0)!,NSForegroundColorAttributeName: UIColor.white])
        
    }
    
    func drawStatText(upperNumber: Double, lowerNumber: Double, xPos: CGFloat, episodeWidth: CGFloat) {
        
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            return formatter
        }()
        
        var frameWidth = episodeWidth
        if frameWidth > 30 {
            frameWidth = 30
        }
        
        let upperRect = CGRect(x: xPos, y: 5, width: frameWidth, height: 16)
        let lowerRect = CGRect(x: xPos , y: upperRect.maxY + 5, width: frameWidth, height: 16)
        let cornerRadius: CGFloat = 2.0
        
        let upperRectPath = UIBezierPath(roundedRect: upperRect, cornerRadius: cornerRadius)
        upperRectPath.lineWidth = 1.0
        colorScheme.medBarRed.setFill()
        upperRectPath.fill()
        upperRectPath.stroke()
        
        let lowerRectPath = UIBezierPath(roundedRect: lowerRect, cornerRadius: cornerRadius)
        lowerRectPath.lineWidth = 1.0
        colorScheme.medBarGreen.setFill()
        lowerRectPath.fill()
        lowerRectPath.stroke()
                
        let upperText = (numberFormatter.string(from: upperNumber as NSNumber) ?? "") + "%"
        upperText.draw(in: upperRect.insetBy(dx: 2, dy: 0), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: 12.0)!,NSForegroundColorAttributeName: UIColor.white])
        
        let lowerText = (numberFormatter.string(from: lowerNumber as NSNumber) ?? "") + "%"
        lowerText.draw(in: lowerRect.insetBy(dx: 2, dy: 0), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: 12.0)!,NSForegroundColorAttributeName: UIColor.white])

    }
    
    func drawTimeLine() {
        
        let dataArray = TimeLineHelper.timeLineArray(timeSpan: displayedTimeSpan, viewWidth: frame.width, minEventDate: minGraphDate, minDisplayDate: minDisplayDate)
        let timeLineTicks = UIBezierPath()
        let timeLineY = bounds.maxY - helper.timeLineSpace()
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
    
    func drawBarGraph() {
        
        guard graphPoints.count > 0  else { return }
        
        let barsPath = UIBezierPath()
        let barWidth: CGFloat = 5.0
        let cornerRadius: CGFloat = 8.0 / 6
        var highestGraphPoint = frame.maxY
        
        let context = UIGraphicsGetCurrentContext()
        for point in graphPoints {
            let columnRect = CGRect(x: point.x - barWidth / 2,
                                    y: point.y,
                                    width: barWidth ,
                                    height:bounds.maxY - helper.timeLineSpace() - point.y
            )
            if columnRect.origin.y < highestGraphPoint {
                highestGraphPoint = columnRect.origin.y
            }
            let columnPath = UIBezierPath(roundedRect: columnRect, cornerRadius: cornerRadius)
            barsPath.append(columnPath)
        }
        
        context!.saveGState()
        (barsPath.copy() as AnyObject).addClip()
        let gradientStartPoint = CGPoint(x: 0, y: highestGraphPoint)
        let gradientEndPoint = CGPoint(x: 0, y: bounds.maxY - helper.timeLineSpace())
        context!.drawLinearGradient(helper.barGraphGradient(), start: gradientStartPoint, end: gradientEndPoint, options: CGGradientDrawingOptions.drawsAfterEndLocation)
        context!.restoreGState()

        barsPath.lineWidth = 1.0
        UIColor.white.setStroke()
        barsPath.stroke()
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
    
    @IBAction func tapGesture(sender: UITapGestureRecognizer) {
        
        medsView.tap(inLocation: sender.location(in: medsView))
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
