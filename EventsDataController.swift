//
//  EventsDataController.swift
//  Alogea
//
//  Created by mikeMBP on 23/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit
import CoreData

typealias scoreEventGraphData = (date: Date, score: CGFloat)


class EventsDataController: NSObject {
    
    // MARK: - CoreData & FRCs
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    lazy var allEventsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("allEventsFRC fetching error")
        }
        
        return frc
    }()
    
    lazy var scoreEventsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "vas > %@", argumentArray: [0.0])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("scoreEventsFRC fetching error")
        }
        
        return frc
    }()
    
    lazy var nonScoreEventTypesFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: ["Diary Entry"])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("nonScoreEventTypesFRC fetching error \(error)")
        }
        
        return frc
    }()
    
    lazy var selectedScoreEventsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let anyScorePredicate = NSPredicate(format: "vas > %@", argumentArray: [0.0])
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
        
//        // MEthod 2
//        
//        
//        let minExpressionDescription = NSExpressionDescription()
//        minExpressionDescription.name = "minimumDate"
//        minExpressionDescription.expression = NSExpression(forFunction: "min:", arguments: [NSExpression(forKeyPath: "date")])
//        minExpressionDescription.expressionResultType = .dateAttributeType
//        
//        let maxExpressionDescription = NSExpressionDescription()
//        maxExpressionDescription.name = "maximumDate"
//        maxExpressionDescription.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "date")])
//        maxExpressionDescription.expressionResultType = .dateAttributeType
//        
//        let dateFetch: NSFetchRequest<Event> = Event.fetchRequest()
//        dateFetch.predicate = NSPredicate(format: "type == %@",firstEvent.type!)
//        dateFetch.propertiesToFetch = [minExpressionDescription, maxExpressionDescription]
//        dateFetch.resultType = .dictionaryResultType
//        dateFetch.includesPendingChanges = true
//        
//        do {
//            let fetchResult = try managedObjectContext.fetch(dateFetch)
//            if fetchResult.count > 1 {
//                selectedEventDates.append(((fetchResult.first! as Event).date as Date?)!)
//                selectedEventDates.append(((fetchResult.last! as Event).date as Date?)!)
//                return selectedEventDates
//            } else {
//                return nil
//            }
//        }
//        catch let error as NSError {
//            print("error fetching earliest selected event date in EventsDataController: \(error)")
//            return nil
//        }
    }

    var selectedScoreEventsTimeSpan: TimeInterval {
        
        guard selectedScoreEventMinMaxDates != nil
            else {
            return (24 * 3600)
        }
        return selectedScoreEventMinMaxDates![1].timeIntervalSince(selectedScoreEventMinMaxDates![0])
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
    
    // MARK: - other properties
    
    var eventTypes = [String]()
    var nonScoreEventTypes = [String]()
    var selectedScore: String {
        if UserDefaults.standard.value(forKey: "SelectedScore") != nil {
            return UserDefaults.standard.value(forKey: "SelectedScore") as! String
        } else {
            UserDefaults.standard.set("untitled", forKey: "SelectedScore")
            return "untitled"
        }
    }
    
    var recordTypesController: RecordTypesController {
        return RecordTypesController.sharedInstance()
    }
    
    weak var graphView: GraphView!
    
    // MARK: - methods
    
    class func sharedInstance() -> EventsDataController {
        return eventsDataController
    }
    
    override init() {
        super.init()
        
        allEventsFRC.delegate = self
        scoreEventsFRC.delegate = self
        eventTypeFRC.delegate = self
        
        for sections in self.eventTypeFRC.sections! {
            eventTypes.append(sections.name)
        }
        for sections in self.nonScoreEventTypesFRC.sections! {
            nonScoreEventTypes.append(sections.name)
        }
        
        reconcileRecordTypesAndEventNames()
    }
    
    func reconcileRecordTypesAndEventNames() {
        
        let scoreEventTypesFRC: NSFetchedResultsController<Event> = {
            let request = NSFetchRequest<Event>(entityName: "Event")
            let anyScorePredicate = NSPredicate(format: "vas > %@", argumentArray: [0.0])
            request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false)]
            request.predicate = anyScorePredicate
            let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "type", cacheName: nil)
            
            do {
                try frc.performFetch()
            } catch let error as NSError{
                print("eventTypesFRC fetching error \(error)")
            }
            
            return frc
        }()
        
        var scoreEventTypes = [String]()
        for sections in scoreEventTypesFRC.sections! {
            scoreEventTypes.append(sections.name)
        }
        
        guard scoreEventTypes.count > 0 else {
            print("no events exist for reconciliation with recordTypes")
            return
        }
        
        for type in scoreEventTypes {
            if !recordTypesController.recordTypeNames.contains(type) {
                recordTypesController.createNewRecordType(withName: type)
                print("there are stored events of type \(type) that have no matching recordType")
                print("a new matching recordType has been created by EventsDataController.reconcile method")
            }
        }
    }
    
    func newEvent(ofType: String, withName: String? = nil, withDate: Date = Date(), vas: Double? = nil, note: String? = nil, duration: Double? = nil) {
        
        let newEvent = NSEntityDescription.insertNewObject(forEntityName: "Event", into: managedObjectContext) as! Event
        
        newEvent.type = ofType
        newEvent.date = withDate as NSDate?
        if withName != nil {
            newEvent.name = withName
        }
        if vas != nil {
            newEvent.vas = vas!
        } else {
            newEvent.vas = -1
        }
        if note != nil {
            newEvent.note = note
        }
        if duration != nil {
            newEvent.duration = duration!
        }
        
        save()
        print("saved a new event \(newEvent)")
    }
    
    func save() {
        (UIApplication.shared.delegate as! AppDelegate).stack.save()
    }
    
    
    func graphData() -> [scoreEventGraphData]? {
        
        guard selectedScoreEventsFRC.fetchedObjects != nil && (selectedScoreEventsFRC.fetchedObjects?.count)! > 0 else {
            return nil
        }
        
        var dataArray = [scoreEventGraphData]()
        for object in selectedScoreEventsFRC.fetchedObjects! {
            if let event = object as Event? {
                let data = (event.date! as Date, CGFloat(event.vas))
                dataArray.append(data)
            }
        }
        return dataArray
    }
    
}

let eventsDataController = EventsDataController()

extension EventsDataController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // allEvents FRC changes always
        
        if controller.isEqual(scoreEventsFRC) {
            print("scoreEventsFRC has changed")
            print("There are \(scoreEventsFRC.fetchedObjects?.count) score events")
            graphView.setNeedsDisplay()
        } else if controller.isEqual(eventTypeFRC) {
            print("eventTypeFRC has changed")
            eventTypes.removeAll(keepingCapacity: true)
            for section in eventTypeFRC.sections! {
                eventTypes.append(section.name)
            }
            print("eventTypeFRC have changed - found the following types: \(eventTypes)")
        } else if controller.isEqual(nonScoreEventTypesFRC) {
            nonScoreEventTypes.removeAll()
            for sections in self.nonScoreEventTypesFRC.sections! {
                nonScoreEventTypes.append(sections.name)
            }
            print("nonScoreEventTypeFRC has changed - found the following types: \(nonScoreEventTypes)")
        }
        reconcileRecordTypesAndEventNames()
    }
    
}

extension EventsDataController {
    
    func createExampleEvents() {
        
        print("create example event of type \(selectedScore)")

        for _ in 0..<Int(10 + drand48() * 100) {
            let _ = drand48()
        }
        
        for _ in 0 ..< Int(10 + drand48() * 40) {
            let newEvent:Event? = {
                NSEntityDescription.insertNewObject(forEntityName: "Event", into: managedObjectContext) as? Event
            }()
            newEvent!.name = selectedScore
            newEvent!.type = selectedScore
            newEvent?.vas = drand48() * 10
            newEvent!.date = NSDate().addingTimeInterval(drand48() * -45 * 24 * 3600)
        }
        
//        do {
//            try  managedObjectContext.save()
//        }
//        catch let error as NSError {
//            print("Error saving \(error)", terminator: "")
//        }
        
        print("there are now \(selectedScoreEventsFRC.fetchedObjects?.count) events of type \(selectedScore)")
        print("earliest Selected event Date \(selectedScoreEventMinMaxDates![0])")
        print("latest Selected event Date \(selectedScoreEventMinMaxDates![1])")

    }
    
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
