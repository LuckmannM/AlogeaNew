//
//  GraphViewHelper.swift
//  Alogea
//
//  Created by mikeMBP on 29/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit
import  CoreData

typealias scoreEventGraphData = (date: Date, score: CGFloat)

class GraphViewHelper: NSObject {
    
    weak var graphView: GraphView!
    let colorScheme = ColorScheme.sharedInstance()
    
    let timeLineTickLength: CGFloat = 5.0
    let timeLineLabelHeight: CGFloat = {
        let label = UILabel()
        label.font = UIFont(name: "AvenirNext-Regular", size: 12.0)
        label.text = "30.12.2020"
        label.sizeToFit()
        return label.frame.height
    }()

    
    // MARK: - Horizontal line format
    let horizontalLineColor = ColorScheme.sharedInstance().lightGray
    let horizontalLineWidth: CGFloat = 1.0
    
    // MARK: - LineGraph format
    let lineGraphCircleRadius: CGFloat = 3.0
    let lineGraphCircleLineWidth: CGFloat = 3.0
    let lineGraphLineWidth: CGFloat = 2.0
    let lineCircleFillColor = ColorScheme.sharedInstance().darkBlue

    // MARK: - BarGraph format
    let barWidth: CGFloat = 8.0
    let barCornerRadius: CGFloat = 8.0 / 6
    let barRimColor = UIColor.white
    let barRimWidth: CGFloat = 1.5
    
    
    // MARK: - GraphView2 timeLine formats
    let tLLineWidth: CGFloat = 2.0
    let tLLineColor = UIColor.white
    
    // MARK: - CoreData and FRC
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()

    var graphEventsFRC: NSFetchedResultsController<Event> {
        
        let frc = EventsDataController.sharedInstance().fetchSpecificEventsFRC(name: self.selectedScore, type: scoreEvent)
        frc.delegate = self
        return frc
    }
    
    var allEventsMinMaxDates: [Date]? {
        
        // return dates from all entered dated events and regular Meds
        // date[0] is first date, date[1] = last date
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        
        var allEvents:[Event]?
        
        do  {
            allEvents = try moc.fetch(fetchRequest)
        }  catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "GVHelper Error 1", systemError: error)
        }
        
        let allRegDrugsFRC = MedicationController.sharedInstance().regMedsSortedByStartDateFRC
        
        guard (allEvents?.count ?? 0) > 0 ||  (allRegDrugsFRC.fetchedObjects?.count ?? 0) > 0 else {
            return nil
        }
        let oneDayAgo = Date().addingTimeInterval(-24 * 3600)
        let firstDate = (allEvents?.first)?.date as? Date ?? oneDayAgo
        var minAndMaxDates = [firstDate] // minDate from one and only event
        minAndMaxDates.append(Date())
        
        if (allRegDrugsFRC.fetchedObjects?.count ?? 0) > 0 {
            let firstDate = (allRegDrugsFRC.object(at: IndexPath(item: 0, section: 0)) as DrugEpisode).startDate as! Date
            if minAndMaxDates.count == 0 {
                minAndMaxDates.append(firstDate) // minDate from one and only regular drug startDate
                minAndMaxDates.append(Date())
            } else {
                if firstDate.compare(minAndMaxDates[0]) == .orderedAscending {
                    minAndMaxDates[0] = firstDate
                }
            }
        }
        return minAndMaxDates
    }
    
    var allGraphEventsTimeSpan: TimeInterval {
        
        guard allEventsMinMaxDates != nil else {
                return (24 * 3600)
        }
        return allEventsMinMaxDates![1].timeIntervalSince(allEventsMinMaxDates![0])
    }
    
    var selectedScoreMinDateToNow: TimeInterval {
        
        guard allEventsMinMaxDates != nil
            else {
                return (24 * 3600)
        }
        return Date().timeIntervalSince(allEventsMinMaxDates![0])
    }
    
    lazy var nonScoreEventsFRC: NSFetchedResultsController<Event>  = {
        return EventsDataController.sharedInstance().nonScoreEventsByDateFRC
    }()
    
    var selectedScore: String {
        if UserDefaults.standard.value(forKey: "SelectedScore") != nil {
            return UserDefaults.standard.value(forKey: "SelectedScore") as! String
        } else {
            UserDefaults.standard.set("untitled", forKey: "SelectedScore")
            return "untitled"
        }
    }
    
    var timeLineHelper: TimeLineHelper!
    
    //MARK: - methods

    convenience init(graphView: GraphView) {
        
        print("init GraphViewHelper")
        self.init()
        self.graphView = graphView
        self.timeLineHelper = TimeLineHelper(helper: self)
        print("finished init GraphViewHelper")
        print("")
    }
    
    class func sharedInstance() -> GraphViewHelper {
        return helper
    }
    
    func lineGraphGradient() -> CGGradient {
        
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let gradientStartColour = colorScheme.pearlWhite.withAlphaComponent(1.0)
        let gradientEndColour = colorScheme.lightGray.withAlphaComponent(0.0)
        let graphGradientColours = [gradientStartColour.cgColor, gradientEndColour.cgColor]
        let graphColourLocations:[CGFloat] = [0.0, 1.0]
        
        return CGGradient(colorsSpace: colourSpace, colors: graphGradientColours as CFArray, locations: graphColourLocations)!
    }
    
    func barGraphGradient() -> CGGradient {
        
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let gradientStartColour = colorScheme.pearlWhite.withAlphaComponent(1.0)
        let gradientEndColour = colorScheme.lightGray.withAlphaComponent(0.3)
        let graphGradientColours = [gradientStartColour.cgColor, gradientEndColour.cgColor]
        let graphColourLocations:[CGFloat] = [0.0, 1.0]
        
        return CGGradient(colorsSpace: colourSpace, colors: graphGradientColours as CFArray, locations: graphColourLocations)!
    }
    
    func timeLineSpace() -> CGFloat {
        return timeLineLabelHeight + timeLineTickLength
    }
    
    
    func maxScore() -> Double {
        
        var score: Double = 10.0
        for object in EventsDataController.sharedInstance().recordTypesController.allTypes.fetchedObjects! {
            if let type = object as RecordType? {
                if type.name == selectedScore { score = (type.maxScore?.doubleValue ?? 10.0) }
            }
        }
        return score
    }
    
    func graphData() -> [scoreEventGraphData]? {
        
        guard (graphEventsFRC.fetchedObjects?.count ?? 0)! > 0 else {
            return nil
        }
        
        var dataArray = [scoreEventGraphData]()
        for object in graphEventsFRC.fetchedObjects! {
            if let event = object as Event? {
                let data = (event.date! as Date, CGFloat(event.vas!.doubleValue))
                dataArray.append(data)
            }
        }
        return dataArray
    }
    
    func calculateGraphPoints(forFrame: CGRect, withDisplayedTimeSpan: TimeInterval, withMinDate: Date) -> [CGPoint] {
        
        var points = [CGPoint]()
        var maxVAS = CGFloat()
        
        guard let scoreEventsData = graphData() else {
            return points
        }
        
        if recordTypesController.returnMaxVAS(forType: helper.selectedScore) == nil {
            maxVAS = 10.0
        } else {
            maxVAS = CGFloat(recordTypesController.returnMaxVAS(forType: helper.selectedScore)!)
        }
        
        let timePerWidth = CGFloat(withDisplayedTimeSpan) / forFrame.width
        
        for eventData in scoreEventsData {
            let xCoordinate = CGFloat(TimeInterval(eventData.date .timeIntervalSince(withMinDate))) / timePerWidth
            let yCoordinate = (forFrame.height - timeLineSpace()) * (maxVAS - eventData.score) / maxVAS
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
            graphView.displayedTimeSpan = newDisplayInterval
            graphView.maxDisplayDate = Date()
            graphView.minDisplayDate = graphView.maxDisplayDate.addingTimeInterval(-graphView.displayedTimeSpan)
        } else {
            graphView.minDisplayDate = toDates![0]
            graphView.maxDisplayDate = toDates![1]
            graphView.displayedTimeSpan = graphView.maxDisplayDate.timeIntervalSince(graphView.minDisplayDate)
        }
        
        graphView.graphContainerView.updateBottomLabel()
        graphView.setNeedsDisplay()
    }


}

let helper = GraphViewHelper()

extension GraphViewHelper: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        graphView.refreshPointsFlag = true
        graphView.setNeedsDisplay()
    }
    
}

// *** Debug only
extension GraphViewHelper {
  
    func printSelectedScoreEventDates() {
        
        for object in graphEventsFRC.fetchedObjects! {
            if let event = object as Event? {
                print("event date \(event.date)")
            }
        }
        
        if allEventsMinMaxDates?.count != nil {
            print("earliest Selected event Date \(allEventsMinMaxDates![0])")
            print("latest Selected event Date \(allEventsMinMaxDates![1])")
        }
    }

}
// *** Debug only

