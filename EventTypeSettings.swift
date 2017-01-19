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
    let textFieldTag = 30
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hidesBottomBarWhenPushed = true
        self.tabBarController!.tabBar.isHidden = true
        tableView.reloadData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return recordTypesController.allTypes.fetchedObjects?.count ?? 0
        } else {
            return eventsController.nonScoreEventTypesFRC.sections?.count ?? 0
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventTypeCell", for: indexPath) as! TextInputCell

        cell.setDelegate(delegate: self,indexPath: indexPath,tableView: self.tableView)
        
        if indexPath.section == 0 {
            // (cell.contentView.viewWithTag(titleTag) as! UILabel).text = recordTypesController.allTypes.object(at: indexPath).name!
            cell.textField.text = recordTypesController.allTypes.object(at: indexPath).name!
        } else {
            let modifiedPath = IndexPath(row: 0, section: indexPath.row)
            // (cell.contentView.viewWithTag(titleTag) as! UILabel).text = eventsController.nonScoreEventTypesFRC.object(at: modifiedPath).name!
            cell.textField.text = eventsController.nonScoreEventTypesFRC.object(at: modifiedPath).name!
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected cell at \(indexPath)")
//        let cell = tableView.cellForRow(at: indexPath) as! TextInputCell
//        tableView.deselectRow(at: indexPath, animated: false)
//        cell.textField.becomeFirstResponder()
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        print("edicAction  at \(indexPath)")
        let renameAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Rename", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in

                var cell = tableView.cellForRow(at: indexPath) as! TextInputCell
                tableView.reloadRows(at: [indexPath], with: .none)
                cell = tableView.cellForRow(at: indexPath) as! TextInputCell
                cell.textField.becomeFirstResponder()
                
        } )
        
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
                
                let deleteAlert = UIAlertController(title: "Delete multiple events?", message: "This will remove all events with this name", preferredStyle: .actionSheet)
                
                let proceedAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: { (deleteAlert)
                    -> Void in
                    
//                    let objectToDelete = self.drugList.object(at: indexPath)
//                    
//                    objectToDelete.cancelNotifications()
//                    self.managedObjectContext.delete(objectToDelete)
//                    self.save()
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (deleteAlert)
                    -> Void in
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                })
                
                deleteAlert.addAction(proceedAction)
                deleteAlert.addAction(cancelAction)
                
                // iPads have different requirements for AlertControllers!
                if UIDevice().userInterfaceIdiom == .pad {
                    let cell = tableView.cellForRow(at: indexPath)
                    let popUpController = deleteAlert.popoverPresentationController
                    popUpController!.permittedArrowDirections = .up
                    popUpController!.sourceView = self.view
                    popUpController!.sourceRect = (cell?.contentView.bounds)!
                }
                
                self.present(deleteAlert, animated: true, completion: nil)
        })
        
        deleteAction.backgroundColor = UIColor.red
        renameAction.backgroundColor = ColorScheme.sharedInstance().darkBlue
        
        return [renameAction, deleteAction]
    
    }
    
    func showRenameAlert(forIndexPath: IndexPath, newName: String) {
        
        var eventType = String()
        if forIndexPath.section == 0 {
            eventType = scoreEvent
        } else {
            eventType = nonScoreEvent
        }
        
        let cell = tableView.cellForRow(at: forIndexPath) as! TextInputCell
        
        let originalName = cell.originalText
        
        let fetchedEventsFRC = EventsDataController.sharedInstance().fetchSpecificEvents(name: originalName!, type: eventType)
        let recordCount = fetchedEventsFRC?.fetchedObjects?.count ?? 0
        
        let alert = UIAlertController(title: "Rename multiple events?", message: "This will change the name of all events (\(recordCount)) with this name", preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Rename", style: UIAlertActionStyle.default, handler: { (alert)
            -> Void in
            
            //                    let objectToDelete = self.drugList.object(at: indexPath)
            //
            //                    objectToDelete.cancelNotifications()
            //                    self.managedObjectContext.delete(objectToDelete)
            //                    self.save()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (alert)
            -> Void in
            
            cell.textField.text = originalName
        })
        
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        
        // iPads have different requirements for AlertControllers!
        if UIDevice().userInterfaceIdiom == .pad {
            let cell = tableView.cellForRow(at: forIndexPath)
            let popUpController = alert.popoverPresentationController
            popUpController!.permittedArrowDirections = .up
            popUpController!.sourceView = self.view
            popUpController!.sourceRect = (cell?.contentView.bounds)!
        }
        
        self.present(alert, animated: true, completion: nil)

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

//extension EventTypeSettings: UITextFieldDelegate {
//    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        
//        //        tableView.deselectRow(at: indexPath, animated: false)
//        
//        let entryField = textField as! TextInputCell
//        originalText = textField.text
//        textField.sizeToFit()
//        print("beginning text editing, original text is \(originalText)")
//    }
//    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        
//        textField.resignFirstResponder()
//        return false
//    }
//    
//    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
//        print("end text editing")
//        if textField.text != nil {
//            delegate.receiveNewText(text: textField.text!, fromCellAtPath: indexPath)
//            //            delegate.showRenameAlert(forIndexPath: indexPath, newName: textField.text!)
//        }
//        return true
//    }
//}
