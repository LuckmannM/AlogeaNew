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

let scoreEvent = "Score Event"
let nonScoreEvent = "Diary Entry"
let medicineEvent = "Medicine Event"


class EventsDataController: NSObject {
    
    // MARK: - CoreData & FRCs
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    //  ** DEVELOPMENT only: used in GV Helper init() function only: if no events created ExampleEvents
    lazy var allEventsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("allEventsFRC fetching error")
        }
        frc.delegate = self
        
        return frc
    }()
    //  ** DEVELOPMENT only

//    lazy var scoreEventsFRC: NSFetchedResultsController<Event> = {
//        let request = NSFetchRequest<Event>(entityName: "Event")
//        let predicate = NSPredicate(format: "type == %@", argumentArray: ["Score Event"])
//        request.predicate = predicate
//        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
//        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
//        
//        do {
//            try frc.performFetch()
//        } catch let error as NSError{
//            print("scoreEventsFRC fetching error")
//        }
//        frc.delegate = self
//        
//        return frc
//    }()
    
    lazy var nonScoreEventTypesFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [nonScoreEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("nonScoreEventTypesFRC fetching error \(error)")
        }
        frc.delegate = self
        
        return frc
    }()
    
    lazy var nonScoreEventsByDateFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [nonScoreEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "date", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("nonScoreEventsByDateFRC fetching error: \(error)")
        }
        frc.delegate = self
        return frc
    }()

    
    lazy var scoreEventTypesFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let anyScorePredicate = NSPredicate(format: "type == %@", argumentArray: [scoreEvent])
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        request.predicate = anyScorePredicate
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("eventTypesFRC fetching error \(error)")
        }
        frc.delegate = self
        
        return frc
    }()
    
    lazy var medicineEventTypesFRC: NSFetchedResultsController<Event> = {
        
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [medicineEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("nonScoreEventTypesFRC fetching error \(error)")
        }
        frc.delegate = self
        
        return frc
    }()

    
    
//    lazy var eventTypeFRC: NSFetchedResultsController<Event> = {
//        let request = NSFetchRequest<Event>(entityName: "Event")
//        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false)]
//        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "type", cacheName: nil)
//        
//        do {
//            try frc.performFetch()
//        } catch let error as NSError{
//            print("eventTypesFRC fetching error")
//        }
//        frc.delegate = self
//        
//        return frc
//    }()
    
    // MARK: - other properties
    
//    lazy var eventTypes: [String] = {
//        var array = [String]()
//        
//        for sections in self.eventTypeFRC.sections! {
//            array.append(sections.name)
//        }
//        
//        return array
//        
//    }()
    
    var nonScoreEventTypes: [String] {
        var array = [String]()
        
        for sections in self.nonScoreEventTypesFRC.sections! {
            array.append(sections.name)
        }
        
        return array
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
        
        reconcileRecordTypesAndEventNames()
        
    }
    
    func reconcileRecordTypesAndEventNames() {
        
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
    
    func fetchSpecificEvents(name: String, type: String) -> NSFetchedResultsController<Event> {
        
        guard type == nonScoreEvent || type == scoreEvent else {
            print("request non-existing events of type \(type) with name \(name)")
            return NSFetchedResultsController<Event>()
        }
        
        let request = NSFetchRequest<Event>(entityName: "Event")
        let typePredicate = NSPredicate(format: "type == %@", argumentArray: [type])
        let namePredicate = NSPredicate(format: "name == %@", argumentArray: [name])
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, namePredicate])
        request.predicate = combinedPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("specificEventsFRC fetching error: \(error)")
            return NSFetchedResultsController<Event>()
        }

        return frc
    }
    
    func renameEvents(ofType: String, oldName: String, newName: String) {
        
        print("renaming events '\(oldName)' with \(newName)...")
        let request = NSFetchRequest<Event>(entityName: "Event")
        let typePredicate = NSPredicate(format: "type == %@", argumentArray: [ofType])
        let namePredicate = NSPredicate(format: "name == %@", argumentArray: [oldName])
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, namePredicate])
        request.predicate = combinedPredicate
        var events:[Event]!
        
        do {
            events = try managedObjectContext.fetch(request)
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        for object in events {
            object.name = newName
        }
        
        save()
    }
    
    func returnUniqueName(name: String) -> String {
        
        var increment: Int!
        var uniqueName = name
        let decimals = NSCharacterSet.decimalDigits
        
        //        print("checking \(name) as unique RecordType; existing are \(recordTypeNames)")
        var lowerEventTypeNames = [String]()
        for type in nonScoreEventTypes {
            lowerEventTypeNames.append(type.lowercased())
        }
        
        while lowerEventTypeNames.contains(uniqueName) {
            
            let range = uniqueName.rangeOfCharacter(from: decimals, options: String.CompareOptions.backwards, range: nil)
            
            if range != nil {
                increment = Int(uniqueName.substring(with: range!))! + 1
                uniqueName.replaceSubrange(range!, with: "\(increment)")
            } else {
                uniqueName = name + " 2"
            }
        }
        //        print("...returning unique variant \(uniqueName)")
        
        return uniqueName
    }

    
}

let eventsDataController = EventsDataController()

extension EventsDataController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        if controller != nonScoreEventsByDateFRC {
            graphView.setNeedsDisplay() // however, this doesn't need to happen if only non-Score events are changed!
        }
        
        reconcileRecordTypesAndEventNames()
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
        
        save()
        
    }
    
//    func deleteAllScoreEvents() {
//        
//        guard (scoreEventsFRC.fetchedObjects?.count)! > 0 else { return }
//        
//        print("deleting all 'Score Events'")
//        
//        for object in scoreEventsFRC.fetchedObjects! {
//            managedObjectContext.delete(object)
//        }
//        save()
//    }
    
}


