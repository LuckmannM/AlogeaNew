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
        let predicate = NSPredicate(format: "type == %@", argumentArray: ["Score Event"])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
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
    
    // MARK: - other properties
    
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
        
        print("init EventsDataController")

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
            let anyScorePredicate = NSPredicate(format: "type == %@", argumentArray: ["Score Event"])
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
        
        // *** debug
//         deleteAllScoreEvents()
//        createExampleEvents()
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
    
    
    
}

let eventsDataController = EventsDataController()

extension EventsDataController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // allEvents FRC changes always
        
        if controller.isEqual(scoreEventsFRC) {
            print("scoreEventsFRC has changed")
            print("There are \(scoreEventsFRC.fetchedObjects?.count) score events")
        } else if controller.isEqual(eventTypeFRC) {
            eventTypes.removeAll(keepingCapacity: true)
            for section in eventTypeFRC.sections! {
                eventTypes.append(section.name)
            }
            print("eventTypeFRC has changed - found the following types: \(eventTypes)")
        } else if controller.isEqual(nonScoreEventTypesFRC) {
            nonScoreEventTypes.removeAll()
            for sections in self.nonScoreEventTypesFRC.sections! {
                nonScoreEventTypes.append(sections.name)
            }
            print("nonScoreEventTypeFRC has changed - found the following types: \(nonScoreEventTypes)")
        }
        reconcileRecordTypesAndEventNames()
        graphView.setNeedsDisplay() // however, this doesn't need to happen if only non-Score events are changed!
    }
    
}


// *** For debuggin only ***
extension EventsDataController {
    
    func createExampleEvents(withName: String = "untitled") {
        

        for _ in 0..<Int(10 + drand48() * 100) {
            let _ = drand48()
        }
        
        for _ in 0 ..< Int(10 + drand48() * 40) {
            let newEvent:Event? = {
                NSEntityDescription.insertNewObject(forEntityName: "Event", into: managedObjectContext) as? Event
            }()
            newEvent!.name = withName
            newEvent!.type = "Score Event"
            newEvent?.vas = drand48() * 10
            newEvent!.date = NSDate().addingTimeInterval(drand48() * -45 * 24 * 3600)
        }
        
//        do {
//            try  managedObjectContext.save()
//        }
//        catch let error as NSError {
//            print("Error saving \(error)", terminator: "")
//        }
        
    }
    
    func deleteAllScoreEvents() {
        
        
        guard (scoreEventsFRC.fetchedObjects?.count)! > 0 else { return }
        
        print("deleting all 'Score Events'")
        
        for object in scoreEventsFRC.fetchedObjects! {
            managedObjectContext.delete(object)
        }
        save()
    }
    
}
