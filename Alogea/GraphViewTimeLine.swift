//
//  GraphViewTimeLine.swift
//  Alogea
//
//  Created by mikeMBP on 04/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit

typealias timeLineParameters = (minCalenderDate: Date, formatter: DateFormatter, timeUnitName: String)
typealias timeLineDataSet = (
    tickPosition: CGFloat,
    tickLabelText: String,
    minTimeLineDate: Date
)

class TimeLineHelper {
    
    static let Second: TimeInterval = 1
    static let Minute: TimeInterval = 60
    static let Minutes15: TimeInterval = 900
    static let Hour: TimeInterval = 3600
    static let Hours4: TimeInterval = 4*3600
    static let Hours12: TimeInterval = 12*3600
    static let Day: TimeInterval = 24*3600
    static let Week: TimeInterval = 7*24*3600
    static let Month: TimeInterval = 365*24*3600/12
    static let Quarter: TimeInterval = 365*24*3600/4
    static let Year: TimeInterval = 365*24*3600

    
    var graphViewHelper: GraphViewHelper!
    
    // Mark: - init and class functions
    
    init(helper: GraphViewHelper) {
        print("init TimeLine")

        self.graphViewHelper = helper
        print("finished init TimeLine")
    }
    
    class func standardTimeIntervals() -> [TimeInterval] {
        let array = [Second,Minute,Minutes15,Hour,Hours4,Hours12,Day,Week,Month,Quarter,Year]
        return array.sorted()
    }
    
    class func timeLineTickInterval(forTimeSpan: TimeInterval, viewWidth: CGFloat) -> TimeInterval {
        /* 
         this functions calculates an optimal number of timeLineTicks, taking into account
         the visibleWidth of the view and an estimated width of a label.text (timeLineLabelSize)
         there should always be more than 2 labels per displayWidth
         */
        
        let targetTickNumber = 5
        let targetTickTimeInterval = forTimeSpan / Double(targetTickNumber)
        let timeUnitArray = standardTimeIntervals()
        
        var previousDifference = forTimeSpan
        var previousUnit = timeUnitArray[0]
        
        for unit in timeUnitArray {
            
            let difference = abs(targetTickTimeInterval - unit)
            if previousDifference < difference {
                if forTimeSpan / unit > 2 {
                    return unit
                } else {
                    return previousUnit
                }
            }
            previousDifference = difference
            previousUnit = unit
        }
        return timeUnitArray.last!
    }

    //Mark: - instance methods
    
    class func timeLineMinDatefromMinEventDate(minDate: Date, timeLineTimeInterval: TimeInterval) -> timeLineParameters {
        
        // returns earlier! standardCalendarUnitDate for minEventDate based on the timeLineTimeUnit
        // eventDates are arbirtrary dates that need to be set in relation to standard dates such as
        // beginning of minute/hour/day/week/month etc
        
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.default
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "dd.MM.yyyy" // time/date symbols shown on the bottom timeLine
            return formatter
        }()
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var standardUnitComponents = calendar.dateComponents(components, from: minDate)
        
        var timeUnitName = String()
        
        // below is calculating the earliest date on the timeLine only.
        // this is taken from the calendar object related to minEventDate (= minTotalDate)
        // setting the earliest 'absolute' date as the next late date.
        // All subsequent dates of the timeLineLabels in drawTimeLine() are
        // calculated by adding increments of 'displayTimeUnitValue' to this leftmost/earliest date
        // this means that the longer dTUV is the more unpredictable the actual labelDate and time will become
        // due to daylightSavintTime events and other dat shifts in between
        // this becomes apparent when using quarters in particular
        // the intervals between timeLineTicks are equal, but their dates will not always be 1st etc
        // for more regularity/predictabiilty consider using weekOfYear/ week based dates
        
        switch timeLineTimeInterval {
        case 0..<Minute:
            standardUnitComponents.second = 0
            standardUnitComponents.minute! -= 1 // next smaller, to appear left of minEventDate on timeline
            timeUnitName = "Seconds"
            dateFormatter.dateFormat = "m:ss"
        case Minute..<Minutes15:
            standardUnitComponents.second = 0
            standardUnitComponents.minute! -= 1
            timeUnitName = "Minutes"
            dateFormatter.timeStyle = .short
        case Minutes15..<Hour:
            standardUnitComponents.second = 0
            switch standardUnitComponents.minute! {
            case 0..<15:
                standardUnitComponents.minute = 0
            case 15..<30:
                standardUnitComponents.minute = 15
            case 30..<45:
                standardUnitComponents.minute = 30
            default:
                standardUnitComponents.minute = 45
            }
            timeUnitName = "15 minutes"
            dateFormatter.timeStyle = .short
        case Hour..<Hours4:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            switch standardUnitComponents.hour! {
            case 0..<4:
                standardUnitComponents.hour = 0
            case 4..<8:
                standardUnitComponents.hour = 4
            case 8..<12:
                standardUnitComponents.hour = 8
            case 12..<16:
                standardUnitComponents.hour = 12
            case 16..<20:
                standardUnitComponents.hour = 16
            default:
                standardUnitComponents.hour = 20
            }
            timeUnitName = "Hours"
            dateFormatter.timeStyle = .short
        case Hours4..<Day:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            standardUnitComponents.hour! -= 1
            timeUnitName = "4 hours"
            if standardUnitComponents.hour == 0 {
                dateFormatter.dateFormat = "d.M."
            } else {
                dateFormatter.timeStyle = .short
            }
        case Day..<Week:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            standardUnitComponents.hour = 0
            standardUnitComponents.day! -= 1
            timeUnitName = "Days"
            dateFormatter.dateFormat = "EEE" // d.M"
        case Week..<Month:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            standardUnitComponents.hour  = 0
            // Sunday =1 , Monday =2
            if standardUnitComponents.weekday == 1 {
                standardUnitComponents.day! -= 1
            } else {
                standardUnitComponents.day! -= 7
            }
            timeUnitName = "Weeks"
            dateFormatter.dateFormat = "d.M"
        case Month..<Quarter:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            standardUnitComponents.hour  = 0
            standardUnitComponents.day = 1
            standardUnitComponents.month! -= 1
            timeUnitName = "Months"
            dateFormatter.dateStyle = .short
        case Quarter...Year:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            standardUnitComponents.hour  = 0
            standardUnitComponents.day = 1
            switch standardUnitComponents.month! {
            case 1...3:
                standardUnitComponents.month = 1
            case 4...6:
                standardUnitComponents.month = 4
            case 7...9:
                standardUnitComponents.month = 7
            default:
                standardUnitComponents.month = 10
            }
            timeUnitName = "Quartiles"
            dateFormatter.dateFormat = "qqq/yy"
        default:
            standardUnitComponents.second = 0
            standardUnitComponents.minute = 0
            standardUnitComponents.hour  = 0
            standardUnitComponents.day = 1
            standardUnitComponents.month = 1
            standardUnitComponents.year! -= 1
            timeUnitName = "Years"
            dateFormatter.dateFormat = "yyyy"
        }
        
        let parameters: timeLineParameters = (calendar.date(from: standardUnitComponents)!, dateFormatter, timeUnitName)
        
        return parameters
    }
    
    class func timeLineArray(timeSpan: TimeInterval, viewWidth: CGFloat, minEventDate: Date, minDisplayDate: Date) -> [timeLineDataSet] {
        
        let now = Date()
        let timeLineScale = (CGFloat(timeSpan) / viewWidth)
        
        // NSTimeInterval between two ticks of the timeLine
        let timeLineTimeInterval = timeLineTickInterval(forTimeSpan: timeSpan, viewWidth: viewWidth)
        
        // firstTLDate is next calendarDate left! of minEVENTDate (not minDisplayDate!)
        // timeLineLabelFormatter is a dateFormatter for the tick labels
        
        let minDate = minEventDate
        
        let (firstTimeLineDate, timeLineLabelFormatter, _) = timeLineMinDatefromMinEventDate(minDate: minDate, timeLineTimeInterval: timeLineTimeInterval)
        
        // the below is negative if firstTimeLineDate is earlier than minDisplayDate

        // timeLineSet is a global/typealias parameter/tuple set at the top of this class
        // it has two elements: a CGFloat for the x-position of the label inside the graphView, and a Uilabel to hold the dateFormat and text for the tick
        var returnSet = [timeLineDataSet]()
        var currentTickDate = firstTimeLineDate
        
        while currentTickDate.compare(now) == .orderedAscending {
            // calculate tickPosition
            let tickX: CGFloat = (CGFloat(currentTickDate.timeIntervalSince(minDisplayDate)) / timeLineScale)
            // join into timeLineSet and append to returnSet array
            returnSet.append((tickX, timeLineLabelFormatter.string(from: currentTickDate), firstTimeLineDate))
            
            currentTickDate = currentTickDate.addingTimeInterval(timeLineTimeInterval)
        }
        
        return returnSet
    }
}
