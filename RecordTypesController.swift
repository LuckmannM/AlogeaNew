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
    
    lazy var allTypes: NSFetchedResultsController<RecordType> = {
        let request = NSFetchRequest<RecordType>(entityName: "RecordType")
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("allRecordTypesFRC fetching error")
        }
        
        return frc
    }()
    
    var recordTypeNames: [String] {
        
        var nameArray = [String]()
        
        guard allTypes.fetchedObjects != nil else {
            print("no recordTypes exist")
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
        print("init RecordTypesDataController")

        allTypes.delegate = self
    }
    
    class func sharedInstance() -> RecordTypesController {
        return recordTypesController
    }
    
    func createNewRecordType(withName: String, minValue: Double? = 0, maxValue: Double? = 10) {
        
        let newType = NSEntityDescription.insertNewObject(forEntityName: "RecordType", into: managedObjectContext) as! RecordType
        
        newType.name = withName
        newType.dateCreated = Date() as NSDate?
        newType.minScore = minValue!
        newType.maxScore = maxValue!
        
        save()
        
    }
    
    func returnMaxVAS(forType: String?) -> Double? {
        
        for object in allTypes.fetchedObjects! {
            if let recordType = object as RecordType? {
                if recordType.name == forType {
                    return recordType.maxScore
                }
            }
        }
        return nil
    }
    
    
    func save() {
        
        do {
            try  managedObjectContext.save()
            // print("saving drugList moc")
        }
        catch let error as NSError {
            print("Error saving \(error)", terminator: "")
        }
    }

    
    
    
}

extension RecordTypesController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // if a recordType is renamed or deleted the EventsDataController must be informed
        // so that all events with that name are renamed or deleted as well
        
        print("recordTypes have been changed")
        
    }
}

let recordTypesController = RecordTypesController()
