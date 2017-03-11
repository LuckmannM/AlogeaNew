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
            ErrorManager.sharedInstance().errorMessage(message: "MedController Error 1", systemError: error)
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
    
    var regMedsFRC: NSFetchedResultsController<DrugEpisode> = {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let regPredicate = NSPredicate(format: "regularly == true")
        
        request.predicate = regPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "regularly", ascending: false), NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedController Error 2", systemError: error)
        }
        
        /* DEBUG
         for object in frc.fetchedObjects! {
         print("prn drug isCurrent is \(object.isCurrent)")
         print("prn drug endDate is \(object.endDate)")
         }
         */
        
        return frc
    }()
    
    var regMedsSortedByStartDateFRC: NSFetchedResultsController<DrugEpisode> {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let regPredicate = NSPredicate(format: "regularly == true")
        
        request.predicate = regPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedController Error 3", systemError: error)
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

    
    var allMedsFRC: NSFetchedResultsController<DrugEpisode> = {
    
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
        try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedController Error 4", systemError: error)
        }
        /* DEBUG
         for object in frc.fetchedObjects! {
         print("prn drug isCurrent is \(object.isCurrent)")
         print("prn drug endDate is \(object.endDate)")
         }
         */
        
        return frc
    }()

    
    var asRequiredMedNames: [(String, Double, String)] {
        
        var nameArray = [(name: String, duration: Double, dose:String)]()
        
        guard asRequiredMedsFRC.fetchedObjects != nil else {
            return nameArray
        }
        
        for object in asRequiredMedsFRC.fetchedObjects! {
            if let recordType = object as DrugEpisode? {
                let pickerStringForMainViewButton = recordType.name!// + " " + recordType.individualDoseString(index: 0,numberOnly: true)
                let medEffectDuration = object.frequency
                let medDoseString = object.individualDoseString(index: 0)
                nameArray.append((pickerStringForMainViewButton, medEffectDuration, medDoseString))
            }
        }
        //print("MedsController found prn drug names: \(nameArray)")
        return nameArray
    }
    
    override init() {
        super.init()
        print("init MedicationController)")
        
        regMedsFRC.delegate = self
        allMedsFRC.delegate = self
        print("finished init MedicationController)")
    }
    
    func returnSingleCurrentMedName() -> String? {
        
        if (allMedsFRC.fetchedObjects?.count)! > 0 {
            return allMedsFRC.fetchedObjects?[0].nameVar
        } else {
            return nil
        }
    }
    
    func countPRNMedEvents(forMedName: String, betweenStartDate: Date? = nil, andEndDate: Date? = nil) -> Int {

        let combinedPredicate: NSCompoundPredicate!
        let request = NSFetchRequest<Event>(entityName: "Event")
        let medPredicate = NSPredicate(format: "type == %@", argumentArray: [medicineEvent])
        let namePredicate = NSPredicate(format: "name == %@", argumentArray: [forMedName])
        if betweenStartDate != nil {
            let startDatePredicate = NSPredicate(format: "date > %@", argumentArray: [betweenStartDate!])
            let endDatePredicate = NSPredicate(format: "date < %@", argumentArray: [andEndDate!])
            combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [medPredicate,namePredicate,startDatePredicate,endDatePredicate])
        } else {
            combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [medPredicate,namePredicate])
            
        }
        
        request.predicate = combinedPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let medEvents = try managedObjectContext.fetch(request)
            return medEvents.count
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedController Error 5", systemError: error, errorInfo: "error fetching named prn medEvents for counting")
            return 0
        }

    }
    
    func returnSingleMed(withID: String) -> [DrugEpisode]? {
        
        let predicate = NSPredicate(format: "drugID == %@", [withID])
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        request.predicate = predicate
        
        do {
            let meds = try managedObjectContext.fetch(request)
            return meds
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedController Error 5.1", systemError: error, errorInfo: "error fetching named  med with id \(withID)for returnSingleMed")
            return nil
        }

    }
    
    func returnFirstRegMedStartDate() -> Date? {
        if (regMedsSortedByStartDateFRC.fetchedObjects?.count ?? 0) > 0 {
            return regMedsSortedByStartDateFRC.fetchedObjects?[0].startDateVar
        } else {
            return nil
        }
    }
    
    func medStats(forMed: DrugEpisode) -> [MedStats]? {
        
        return StatisticsController.sharedInstance().singleMedStats(forMed: forMed)
        
    }
    
    
    // - Methods:
    
    
//    private func medsTakenBetween(startDate: Date, endDate: Date) -> NSFetchedResultsController<DrugEpisode> {
//        
//        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
//
//        // let startedBeforeEndDate = NSPredicate(format: "startDate < %@",[endDate])
//        // let notEndedBeforeStartDate = NSPredicate(format: "endDate > %@",startDate as CVarArg)
//        let regularly = NSPredicate(format: "regularly == true")
//        
//        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [regularly])
//        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
//        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//        
//        do {
//            try frc.performFetch()
//        } catch let error as NSError{
//            print("prnMedsFRC fetching error: \(error)")
//        }
//        frc.delegate = self
//        
//        /* DEBUG
//         for object in frc.fetchedObjects! {
//         print("prn drug isCurrent is \(object.isCurrent)")
//         print("prn drug endDate is \(object.endDate)")
//         }
//         */
//        
//        return frc
//    }
//    
//    func medViewRegularMedRects(minDate: Date, maxDate: Date, displayWidth: CGFloat) -> [CGRect]{
//        
//        let displayedTimeSpan = maxDate.timeIntervalSince(minDate)
//        let timePerPixel = displayedTimeSpan / TimeInterval(displayWidth)
//        let medsToDisplay = medsTakenBetween(startDate: minDate, endDate: maxDate)
//        var medRects = [CGRect]()
//        
//        let rectHeight: CGFloat = 10
//        let rectGap: CGFloat = 2
//        
//        var count: CGFloat = 0
//        for med in medsToDisplay.fetchedObjects! {
//            let rectLength = med.graphicalDuration(scale: timePerPixel)
//            let rectStartX = CGFloat(med.startDate!.timeIntervalSince(minDate) / timePerPixel)
//            let rect = CGRect(
//                x: rectStartX,
//                y: 0 - rectHeight, //-count * rectGap - count * rectHeight - rectHeight,
//                width: rectLength,
//                height: rectHeight
//            )
//            medRects.append(rect)
//            count += 1
//        }
//        return medRects
//    
//    }

}

extension MedicationController: NSFetchedResultsControllerDelegate {
    
    
}
