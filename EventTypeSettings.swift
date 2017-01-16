//
//  EventTypeSettings.swift
//  Alogea
//
//  Created by mikeMBP on 14/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class EventTypeSettings: UITableViewController {
    
    var stack: CoreDataStack!
    var rootViewController: UIViewController!
    
    var recordTypesController = RecordTypesController.sharedInstance()
    var eventsController = EventsDataController.sharedInstance()
    
    let titleTag = 10
    let subTitleTag = 20
    
//    lazy var managedObjectContext: NSManagedObjectContext = {
//        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
//        return moc
//    }()
//    
//    lazy var nonScoreEventTypesFRC: NSFetchedResultsController<Event> = {
//        let request = NSFetchRequest<Event>(entityName: "Event")
//        let predicate = NSPredicate(format: "type == %@", argumentArray: ["Diary Entry"])
//        request.predicate = predicate
//        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false), NSSortDescriptor(key: "date", ascending: true)]
//        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
//        
//        do {
//            try frc.performFetch()
//        } catch let error as NSError{
//            print("nonScoreEventTypesFRC fetching error \(error)")
//        }
//        frc.delegate = self
//        
//        return frc
//    }()
//
//    lazy var recordTypes: NSFetchedResultsController<RecordType> = {
//        let request = NSFetchRequest<RecordType>(entityName: "RecordType")
//        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
//        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//        
//        do {
//            try frc.performFetch()
//        } catch let error as NSError{
//            print("allRecordTypesFRC fetching error")
//        }
//        frc.delegate = self
//        
//        return frc
//    }()

    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
//        print("load EventTypeSettings VC, scoreEventTypesFRC has \(EventsDataController.sharedInstance().scoreEventsFRC.fetchedObjects?.count ?? 0) objects")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hidesBottomBarWhenPushed = true
        self.tabBarController!.tabBar.isHidden = true
        tableView.reloadData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
//            print("recordTypesController.allTypes has \(recordTypesController.allTypes.fetchedObjects?.count) objects)")
//            print("these are...")
//            for object in recordTypesController.allTypes.fetchedObjects! {
//                print("name \(object.name)")
//            }
            return recordTypesController.allTypes.fetchedObjects?.count ?? 0
//            return recordTypes.fetchedObjects?.count ?? 0
        } else {
//            print("eventsController.nonScoreEventTypesFRC has \(eventsController.nonScoreEventTypesFRC.fetchedObjects?.count) objects)")
//            print("these are...")
//            for object in eventsController.nonScoreEventTypesFRC.fetchedObjects! {
//                print("name \(object.name), type is \(object.type)")
//            }
            return eventsController.nonScoreEventTypesFRC.sections?.count ?? 0
//            return nonScoreEventTypesFRC.fetchedObjects?.count ?? 0
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTypeCell", for: indexPath)

        if indexPath.section == 0 {
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = recordTypesController.allTypes.object(at: indexPath).name!
        } else {
            let modifiedPath = IndexPath(row: 0, section: indexPath.row)
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = eventsController.nonScoreEventTypesFRC.object(at: modifiedPath).name!
            
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return "Symptoms"
        } else {
            return "Event categories"
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        let textSize: CGFloat = 22 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width
        header.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: textSize)
        header.textLabel?.sizeToFit()
        
        header.textLabel?.textColor = UIColor.darkGray
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//extension EventTypeSettings: NSFetchedResultsControllerDelegate {
//
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        print("EventTypes FRCs will change content")
//        tableView.beginUpdates()
//    }
//    
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        
//        tableView.endUpdates()
//        print("EventTypes FRCs finished changing content")
//    }
//    
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        
//        // applies to recordTypes FRC
//
//        switch type {
//        case .update:
//            tableView.reloadRows(at: [indexPath!], with: .automatic)
//        case .insert:
//            tableView.insertRows(at: [newIndexPath!], with: .automatic)
//        case .delete:
//            tableView.deleteRows(at: [indexPath!], with: .automatic)
//        case .move:
//            tableView.deleteRows(at: [indexPath!], with: .automatic)
//            tableView.insertRows(at: [newIndexPath!], with: .automatic)
//            // using .moveRow() causes a problem as the moved row fails to fade away the rowActionMenu
//            // using .deselectRow doesn't help
//        }
//    }
//    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
//    {
//        
//        // applies to nonScoreEventTypes FRC which is organised by sectionNameKeyPath 'name'
//        
//        let indexSet = NSIndexSet(index: sectionIndex) as IndexSet
//        
//        
//        switch type {
//        case .insert:
//            // print("inserting section \(sectionInfo.name)")
//            tableView.insertSections(indexSet, with: .automatic)
//        case .delete:
//            // print("deleting section \(sectionInfo.name)")
//            tableView.deleteSections(indexSet, with: .automatic)
//        case .update:
//            // print("updating section \(sectionInfo.name)")
//            tableView.reloadSections([sectionIndex], with: .automatic)
//        case .move:
//            print("move section \(sectionInfo.name) at index \(sectionIndex)")
//        }
//    }
//
//
//}
