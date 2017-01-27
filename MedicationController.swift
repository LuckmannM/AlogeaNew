//
//  MedicationController.swift
//  Alogea
//
//  Created by mikeMBP on 25/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let medicationController = MedicationController()

class MedicationController: NSObject {
    
    // MARK: - methods
    
    class func sharedInstance() -> MedicationController {
        return medicationController
    }

    
    // MARK: - CoreData & FRCs
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    //  ** DEVELOPMENT only: used in GV Helper init() function only: if no events created ExampleEvents
    lazy var asRequiredMedsFRC: NSFetchedResultsController<DrugEpisode> = {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let prnPredicate = NSPredicate(format: "regularly == false")
        let currentPredicate1 = NSPredicate(format: "endDate = nil")
        let currentPredicate2 = NSPredicate(format: "endDate > %@",NSDate())
        let currentCombinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [currentPredicate1, currentPredicate2])
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [prnPredicate,currentCombinedPredicate])
        
        request.predicate = combinedPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "regularly", ascending: false), NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("prnMedsFRC fetching error")
        }
        frc.delegate = self
        
        /* DEBUG
        for object in frc.fetchedObjects! {
            print("prn drug isCurrent is \(object.isCurrent)")
            print("prn drug endDate is \(object.endDate)")
        }
        */
        
        return frc
    }()
    
    lazy var allMedsFRC: NSFetchedResultsController<DrugEpisode> = {
    
    let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
    
    request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
    let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    
    do {
    try frc.performFetch()
    } catch let error as NSError{
    print("prnMedsFRC fetching error")
    }
    frc.delegate = self
    
    /* DEBUG
     for object in frc.fetchedObjects! {
     print("prn drug isCurrent is \(object.isCurrent)")
     print("prn drug endDate is \(object.endDate)")
     }
     */
    
    return frc
    }()

    
    var asRequiredMedNames: [String] {
        
        var nameArray = [String]()
        
        guard asRequiredMedsFRC.fetchedObjects != nil else {
            print("no pernMedicines exist")
            return nameArray
        }
        
        for object in asRequiredMedsFRC.fetchedObjects! {
            if let recordType = object as DrugEpisode? {
                let pickerStringForMainViewButton = recordType.name!// + " " + recordType.individualDoseString(index: 0,numberOnly: true)
                nameArray.append(pickerStringForMainViewButton)
            }
        }
        //print("MedsController found prn drug names: \(nameArray)")
        return nameArray
    }
    
    // - Methods:
    
    
    func medsTakenBetween(startDate: Date, endDate: Date) -> NSFetchedResultsController<DrugEpisode> {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")

        let startedBeforeEndDate = NSPredicate(format: "startDate < %@",endDate as CVarArg)
        let notEndedBeforeStartDate = NSPredicate(format: "endDate > %@",startDate as CVarArg)
        let regularly = NSPredicate(format: "regularly == true")
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startedBeforeEndDate,notEndedBeforeStartDate,regularly])
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("prnMedsFRC fetching error: \(error)")
        }
        frc.delegate = self
        
        /* DEBUG
         for object in frc.fetchedObjects! {
         print("prn drug isCurrent is \(object.isCurrent)")
         print("prn drug endDate is \(object.endDate)")
         }
         */
        
        return frc
        
        
    }

}

extension MedicationController: NSFetchedResultsControllerDelegate {
    
}
