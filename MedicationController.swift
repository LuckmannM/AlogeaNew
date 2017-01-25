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
        let currentPredicate = NSPredicate(format: "isCurrent != %@",["Discontinued Medicines"]) // *** this may not work properly as isCurrent is only updated after fetch AND is an optional parameter which may not properly work as Predicate parameter
        
        // an alternative is using endDate which however, is alos optional so two exclusions would ahve to happen: Predicate would need to include: is either nil or later then current Date()
        
        //let currentPredicate = NSPredicate(format: "endDate == nil",["Current Medicines"])
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [prnPredicate,currentPredicate])
        
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


}

extension MedicationController: NSFetchedResultsControllerDelegate {
    
}
