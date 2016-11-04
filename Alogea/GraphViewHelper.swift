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
    let lineGraphCircleRadius: CGFloat = 4.0
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

    
    lazy var selectedScoreEventsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let anyScorePredicate = NSPredicate(format: "type == %@", argumentArray: ["Score Event"])
        let selectedScorePredicate = NSPredicate(format: "name == %@", argumentArray: [self.selectedScore])
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [anyScorePredicate, selectedScorePredicate])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("selectedScoreEventsFRC fetching error")
        }
        
        return frc
    }()
    
    var selectedScoreEventMinMaxDates: [Date]? {
        
        guard selectedScoreEventsFRC.fetchedObjects != nil && (selectedScoreEventsFRC.fetchedObjects?.count)! > 0 else {
            return nil
        }
        
        guard (selectedScoreEventsFRC.fetchedObjects![0] as Event?) != nil else {
            return nil
        }
        
        var selectedEventDates = [Date]()
        
        if selectedScoreEventsFRC.fetchedObjects!.count < 2 {
            let firstObjectPath = IndexPath(item: 0, section: 0)
            let firstDate = (selectedScoreEventsFRC.object(at: firstObjectPath) as Event).date as! Date
            selectedEventDates.append(firstDate) // minDate from one and only event
            selectedEventDates.append(Date()) // maxDate is now
        } else {
            let firstObjectPath = IndexPath(item: 0, section: 0)
            let lastObjectPath = IndexPath(item: selectedScoreEventsFRC.fetchedObjects!.count - 1, section: 0)
            let firstDate = (selectedScoreEventsFRC.object(at: firstObjectPath) as Event).date as! Date
            selectedEventDates.append(firstDate) // minDate from one and only event
            let lastDate = (selectedScoreEventsFRC.object(at: lastObjectPath) as Event).date as! Date
            selectedEventDates.append(lastDate) // maxDate is now
        }
        
        return selectedEventDates
    }
    
    var selectedScoreEventsTimeSpan: TimeInterval {
        
        guard selectedScoreEventMinMaxDates != nil
            else {
                return (24 * 3600)
        }
        return selectedScoreEventMinMaxDates![1].timeIntervalSince(selectedScoreEventMinMaxDates![0])
    }
    
    var selectedScoreMinDateToNow: TimeInterval {
        
        guard selectedScoreEventMinMaxDates != nil
            else {
                return (24 * 3600)
        }
        return Date().timeIntervalSince(selectedScoreEventMinMaxDates![0])
    }
    
    lazy var eventTypeFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "type", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("eventTypesFRC fetching error")
        }
        
        return frc
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
        self.init()
        
        self.graphView = graphView
        selectedScoreEventsFRC.delegate = self
        self.timeLineHelper = TimeLineHelper(helper: self)
        
    }
    
    class func sharedInstance() -> GraphViewHelper {
        return helper
    }
    
    func lineGraphGradient() -> CGGradient {
        
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let gradientStartColour = colorScheme.lightGray.withAlphaComponent(0.8)
        let gradientEndColour = colorScheme.lightGray.withAlphaComponent(0.0)
        let graphGradientColours = [gradientStartColour.cgColor, gradientEndColour.cgColor]
        let graphColourLocations:[CGFloat] = [0.0, 1.0]
        return CGGradient(colorsSpace: colourSpace, colors: graphGradientColours as CFArray, locations: graphColourLocations)!
        
    }
    
    func barGraphGradient() -> CGGradient {
        
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let colourLocationsForColumns: [CGFloat] = [0.2,0.5,0.8,1.0]
        let coloursForColumns = [UIColor.red.cgColor, UIColor.orange.cgColor, UIColor.yellow.cgColor,UIColor.green.cgColor]
        return CGGradient(colorsSpace: colourSpace, colors: coloursForColumns as CFArray, locations: colourLocationsForColumns)!
    }
    
    func timeLineSpace() -> CGFloat {
        return timeLineLabelHeight + timeLineTickLength
    }
    
    
    func maxScore() -> Double {
        
        var score: Double = 10.0
        for object in EventsDataController.sharedInstance().recordTypesController.allTypes.fetchedObjects! {
            if let type = object as RecordType? {
                if type.name == selectedScore { score = type.maxScore }
            }
        }
        return score
    }
    
    func graphData() -> [scoreEventGraphData]? {
        
        guard selectedScoreEventsFRC.fetchedObjects != nil && (selectedScoreEventsFRC.fetchedObjects?.count)! > 0 else {
            return nil
        }
        
        // *** debug only
        // print("there are \(selectedScoreEventsFRC.fetchedObjects!.count) selected scoreEvents named '\(selectedScore)'")
        // *** debug only
        
        var dataArray = [scoreEventGraphData]()
        for object in selectedScoreEventsFRC.fetchedObjects! {
            if let event = object as Event? {
                let data = (event.date! as Date, CGFloat(event.vas))
                dataArray.append(data)
            }
        }
        return dataArray
    }
    
    func calculateGraphPoints(forFrame: CGRect, withDisplayedTimeSpan: TimeInterval, withMinDate: Date) -> [CGPoint] {
        
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
        
        graphView.setNeedsDisplay()
    }


}

let helper = GraphViewHelper()

extension GraphViewHelper: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("GV Helper selectedScoreEventsFRC has changed content")
        graphView.setNeedsDisplay()
    }
    
}

// *** Debug only
extension GraphViewHelper {
  
    func printSelectedScoreEventDates() {
        
        for object in selectedScoreEventsFRC.fetchedObjects! {
            if let event = object as Event? {
                print("event date \(event.date)")
            }
        }
        
        print("earliest Selected event Date \(selectedScoreEventMinMaxDates![0])")
        print("latest Selected event Date \(selectedScoreEventMinMaxDates![1])")
    }

}
// *** Debug only

