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

class EventsDataController: NSObject {
        
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
    
    func selectedScoreEventsLineGraphData(forViewSize: CGSize, displayedTimeSpan: TimeInterval) -> [CGPoint] {
        
        var array = [CGPoint]()
        var maxYValue: CGFloat = forViewSize.height
        
        // this positions the earliest event relative to timeInterval from/to minDisplayDate based on scale
        // and calculates all other values from this point to the right
        guard selectedScoreEventsFRC.fetchedObjects != nil && (selectedScoreEventsFRC.fetchedObjects?.count)! > 0 else {
            return array
        }
        
        
        return array
    }
}

let eventsDataController = EventsDataController()

extension EventsDataController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // allEvents FRC changes always
        
        if controller.isEqual(scoreEventsFRC) {
            print("scoreEventsFRC has changed")
            print("There are \(scoreEventsFRC.fetchedObjects?.count) score events")
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
