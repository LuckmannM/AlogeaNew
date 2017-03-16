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
    
    let subTitleTag = 20
    let textFieldTag = 30
    

    override func viewDidLoad() {
        super.viewDidLoad()

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
            cell.textField.text = recordTypesController.allTypes.object(at: indexPath).name!
            cell.SubLabel.text = "\(eventsController.fetchSpecificEventsFRC(name: cell.textField.text!, type: scoreEvent).fetchedObjects?.count ?? 0) events"
            if (eventsController.fetchSpecificEventsFRC(name: cell.textField.text!, type: scoreEvent).fetchedObjects?.count ?? 0) > 0 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
        } else {
            let modifiedPath = IndexPath(row: 0, section: indexPath.row)
            cell.textField.text = eventsController.nonScoreEventTypesFRC.object(at: modifiedPath).name!
            cell.SubLabel.text = "\(eventsController.fetchSpecificEventsFRC(name: cell.textField.text!, type: nonScoreEvent).fetchedObjects?.count ?? 0) events"
            if (eventsController.fetchSpecificEventsFRC(name: cell.textField.text!, type: nonScoreEvent).fetchedObjects?.count ?? 0) > 0 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return "Symptoms for Graph"
        } else {
            return "Diary Event Types"
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

        let cell = tableView.cellForRow(at: indexPath) as! TextInputCell
        tableView.deselectRow(at: indexPath, animated: false)
        
        if cell.accessoryType == .disclosureIndicator {
            let modifiedPath = IndexPath(row: 0, section: indexPath.row)
            var frc: NSFetchedResultsController<Event>!
            
            if indexPath.section == 0 {
                let name = recordTypesController.allTypes.object(at: indexPath).name!
                frc = eventsController.fetchSpecificEventsFRC(name: name, type: scoreEvent)
            } else {
                let name = eventsController.nonScoreEventTypesFRC.object(at: modifiedPath).name!
                frc = eventsController.fetchSpecificEventsFRC(name: name, type: nonScoreEvent)
            }
            
            performSegue(withIdentifier: "toEventsListSegue", sender: frc)
            
        } else {
            cell.textField.becomeFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let modifiedPath = IndexPath(row: 0, section: indexPath.row)
        var frc: NSFetchedResultsController<Event>!
        
        if indexPath.section == 0 {
            let name = recordTypesController.allTypes.object(at: indexPath).name!
            frc = eventsController.fetchSpecificEventsFRC(name: name, type: scoreEvent)
        } else {
            let name = eventsController.nonScoreEventTypesFRC.object(at: modifiedPath).name!
            frc = eventsController.fetchSpecificEventsFRC(name: name, type: nonScoreEvent)
        }

        performSegue(withIdentifier: "toEventsListSegue", sender: frc)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let renameAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Rename", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in

                var cell = tableView.cellForRow(at: indexPath) as! TextInputCell
                tableView.reloadRows(at: [indexPath], with: .none)
                cell = tableView.cellForRow(at: indexPath) as! TextInputCell
                cell.textField.isUserInteractionEnabled = true
                cell.textField.becomeFirstResponder()
                
        } )
        
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
                
                let cell = tableView.cellForRow(at: indexPath) as! TextInputCell
                let name = cell.textField.text!
                
                var eventType = String()
                if indexPath.section == 0 {
                    eventType = scoreEvent
                } else {
                    eventType = nonScoreEvent
                }
                let fetchedEventsFRC = EventsDataController.sharedInstance().fetchSpecificEventsFRC(name: name, type: eventType)

                let deleteAlert = UIAlertController(title: "Delete multiple events?", message: "This will remove \(fetchedEventsFRC.fetchedObjects?.count ?? 0) events with this name", preferredStyle: .actionSheet)
                
                let proceedAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: { (deleteAlert)
                    -> Void in
                    
                    for object in fetchedEventsFRC.fetchedObjects! {
                        self.stack.context.delete(object)
                    }
                    if indexPath.section == 0 { // scoreEvents only require active update of recordTypes controller
                        self.stack.context.delete(self.recordTypesController.allTypes.object(at: indexPath))
                    }
                    
                    self.save()
                    
                    // if deleting the currently selected score need to change selectedScore to some other
                    // possibility of no remainig RecordType if deleted was the last remaining
                    if name == UserDefaults.standard.value(forKey: "SelectedScore")as! String  {
                        if (RecordTypesController.sharedInstance().allTypes.fetchedObjects?.count ?? 0) > 0 {
                            UserDefaults.standard.set(RecordTypesController.sharedInstance().recordTypeNames[0], forKey: "SelectedScore")
                        } else {
                            // no more RecordTypes exist
                            RecordTypesController.sharedInstance().createNewRecordType(withName: "default")
                            UserDefaults.standard.set("default", forKey: "SelectedScore")
                        }
                    }

                    tableView.reloadSections([indexPath.section], with: .automatic)
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
        
        let fetchedEventsFRC = EventsDataController.sharedInstance().fetchSpecificEventsFRC(name: originalName!, type: eventType)
        let recordCount = fetchedEventsFRC.fetchedObjects?.count ?? 0
        
        let alert = UIAlertController(title: "Rename multiple events?", message: "This will change the name of all events (\(recordCount)) with this name", preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Rename", style: UIAlertActionStyle.default, handler: { (alert)
            -> Void in
            
            if originalName == UserDefaults.standard.value(forKey: "SelectedScore") as? String {
                UserDefaults.standard.set(newName, forKey: "SelectedScore")
            }
            
            if eventType == scoreEvent {
                RecordTypesController.sharedInstance().rename(oldName: originalName!, newName: newName)
            }
            
            EventsDataController.sharedInstance().renameEvents(ofType: eventType, oldName: originalName!, newName: newName)
            
            self.tableView.reloadSections([forIndexPath.section], with: .automatic)
            cell.textField.isUserInteractionEnabled = false
            
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
    
    
    func save() {
        
        do {
            try  stack.context.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "EventTypeSettings Error 1", showInVC: self, systemError: error)
        }
        
    }
    
    //Mark: - Navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toEventsListSegue" {
            if let destination = segue.destination as? EventsListViewController {
                destination.eventsFRC = sender as! NSFetchedResultsController<Event>
                destination.stack = stack
            }
        }
    }

}
