//
//  RecordTypesController.swift
//  Alogea
//
//  Created by mikeMBP on 27/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

class RecordTypesController: NSObject {
    
    // this FRC contains the symptom types (different pains, sleep, mood ...) that the user creates, that are separeately plotted as score graphs in graphView
    // they are stored in the RecordType class object
    // the recordTypes are linked to an optional group of events with the recordType.name as event.name (! not .type)
    // all events of type 'score' (those with .vas>=0) should have a .name that is included in the recordType.name list
    // not all recordTypes will have events saved with that name if the user hasn't entered any yet
    // discepancies between recordTypes and event with their name can arise if the user changes a recordType.name or deletes a recordType. In case of renaming all events with that types name have to be changed as well. If a user deletes a recordType logic requires that all events with that name are deleted as well
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    var allTypes: NSFetchedResultsController<RecordType> = {
        let request = NSFetchRequest<RecordType>(entityName: "RecordType")
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "RecTypeController Error 1", systemError: error)
        }
        
        return frc
    }()
    
    var recordTypeNames: [String] {
        
        var nameArray = [String]()
        
        guard allTypes.fetchedObjects != nil else {
            return nameArray
        }
        
        for recordObject in allTypes.fetchedObjects! {
            if let recordType = recordObject as RecordType? {
                nameArray.append(recordType.name!)
            }
        }
        return nameArray
    }
    
    var eventsController: EventsDataController {
        return EventsDataController.sharedInstance()
    }

    // MARK: Functions
    
    override init() {
        super.init()
        
//        for object in allTypes.fetchedObjects! {
//            print("recordType name is \(object.name) ")
//        }
        
        // check all scoreEventTypes from EventsDataController to see whether a RecordType for each different scoreEvent exists
//        for section in EventsDataController.sharedInstance().scoreEventTypesFRC.sections! {
//            if !recordTypeNames.contains(section.name) {
//                // create new RecordType
//            }
//        }
        
        allTypes.delegate = self

    }
    
    class func sharedInstance() -> RecordTypesController {
        return recordTypesController
    }
    
    func cleanDuplicatesAfterMerge() {
        
        guard allTypes.fetchedObjects != nil else {
            return
        }
        
        guard allTypes.fetchedObjects!.count > 1 else {
            return
        }
        
        for type in allTypes.fetchedObjects! {
            var count = 0
            for scoreName in recordTypeNames {
                if type.name == scoreName {
                    count += 1
                    if count > 1 {
                        managedObjectContext.delete(type)
                    }
                }
            }
        }

    }
    
    func createNewRecordType(withName: String, minValue: Double? = 0, maxValue: Double? = 10, saveHere: Bool = true) {
        
        let newType = NSEntityDescription.insertNewObject(forEntityName: "RecordType", into: managedObjectContext) as! RecordType
        
        newType.name = withName
        newType.dateCreated = Date() as NSDate?
        newType.minScore = minValue! as NSNumber?
        newType.maxScore = maxValue! as NSNumber?
        
        if saveHere {
            save()
        }
        
    }
    
    func returnMaxVAS(forType: String?) -> Double? {
        
        for object in allTypes.fetchedObjects! {
            if let recordType = object as RecordType? {
                if recordType.name == forType {
                    return recordType.maxScore?.doubleValue
                }
            }
        }
        return nil
    }
    
    func returnRecordTypesWithSavedEvents() -> [RecordType] {
        
        var scoreTypes = [RecordType]()
        
        for type in allTypes.fetchedObjects! {
            let events = EventsDataController.sharedInstance().fetchSpecificEventsFRC(name: type.name!, type: scoreEvent)
            if (events.fetchedObjects?.count ?? 0) > 0 {
                scoreTypes.append(type)
            }
        }
        return scoreTypes
    
    }
    
    func rename(oldName: String, newName: String) {
        
        let request = NSFetchRequest<RecordType>(entityName: "RecordType")
        let predicate = NSPredicate(format: "name == %@", argumentArray: [oldName])
        request.predicate = predicate
        var record:[RecordType]!
        
        do {
            record = try managedObjectContext.fetch(request)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "RecTypeController Error 2", systemError: error)
        }
        for object in record {
            object.name = newName
        }
        
        save()
    }
    
    func returnUniqueName(name: String) -> String {
        
        var increment: Int!
        var uniqueName = name
        let decimals = NSCharacterSet.decimalDigits
        
        var lowerRecordTypeNames = [String]()
        for type in recordTypeNames {
            lowerRecordTypeNames.append(type.lowercased())
        }

        while lowerRecordTypeNames.contains(uniqueName) {
            
            let range = uniqueName.rangeOfCharacter(from: decimals, options: String.CompareOptions.backwards, range: nil)
            
            if range != nil {
                increment = Int(uniqueName.substring(with: range!))! + 1
                uniqueName.replaceSubrange(range!, with: "\(increment)")
            } else {
                uniqueName = name + " 2"
            }
        }
        return uniqueName
    }
    
    
    func save() {
        
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "RecTypeController Error 3", systemError: error)
            }
        }

        /*
        do {
            try  managedObjectContext.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "RecTypeController Error 3", systemError: error)
        }
        */
    }

    func scoreStats(forScoreType: String) -> ScoreTypeStats? {
        
        let statsForScoreTypesWithSavedEvents = StatisticsController.sharedInstance().calculateScoreTypeStats()
        
        for stats in statsForScoreTypesWithSavedEvents {
            if stats.scoreTypeName == forScoreType {
                return stats
            }
        }
        
        return nil
    }
    
    
}

extension RecordTypesController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // if a recordType is renamed or deleted the EventsDataController must be informed
        // so that all events with that name are renamed or deleted as well
        
//        print("recordTypes have been changed, now have \(allTypes.fetchedObjects?.count ?? 0) objects")
//        for object in allTypes.fetchedObjects! {
//            print("recordType name is \(object.name) ")
//        }
        
    }
}

let recordTypesController = RecordTypesController()
