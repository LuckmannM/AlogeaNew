//
//  EventsListViewController.swift
//  Alogea
//
//  Created by mikeMBP on 07/03/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

class EventsListViewController: UITableViewController {
    
    var eventsFRC: NSFetchedResultsController<Event>!
    
    var stack: CoreDataStack!

    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    
    var selectedCellsPaths = [IndexPath]()

    override func viewDidLoad() {
        super.viewDidLoad()
        eventsFRC.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsFRC.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventsViewCell", for: indexPath)
        var titleText = String()
        
        if (eventsFRC.object(at: indexPath).vas?.doubleValue ?? -1) >= 0.0 {
            let scoreNumber = numberFormatter.string(from: eventsFRC.object(at: indexPath).vas ?? 0)
            titleText = eventsFRC.object(at: indexPath).name! + ", score: " + (scoreNumber ?? "")
        } else {
            titleText = eventsFRC.object(at: indexPath).name!
        }
        
        (cell.contentView.viewWithTag(10) as! UILabel).text = titleText
        (cell.contentView.viewWithTag(10) as! UILabel).sizeToFit()
 
        (cell.contentView.viewWithTag(20) as! UILabel).text = dateFormatter.string(from: eventsFRC.object(at: indexPath).date as! Date)
        (cell.contentView.viewWithTag(20) as! UILabel).sizeToFit()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Select events to delete"

    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        let textSize: CGFloat = 22 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width
        header.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: textSize)
        header.textLabel?.sizeToFit()
        
        header.textLabel?.textColor = ColorScheme.sharedInstance().duskBlue
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        
        if cell?.accessoryType == UITableViewCellAccessoryType.none {
            cell?.accessoryType = .checkmark
            selectedCellsPaths.append(indexPath)
        } else {
            cell?.accessoryType = .none
            var count = 0
            
            for path in selectedCellsPaths {
                if path == indexPath {
                    selectedCellsPaths.remove(at: count)
                }
                count += 1
            }
        }
        
        if selectedCellsPaths.count > 0 {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(startDeleteSelection))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
                
                self.deleteSelected(atPath: indexPath)
                
        })
        
        deleteAction.backgroundColor = UIColor.red
        
        return [deleteAction]
    }


    func save() {
        
        do {
            try  stack.context.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "EventListVC Error 1", showInVC: self, systemError: error, errorInfo: "error when trying to save moc after event deletion")
        }
        
    }
    
    func startDeleteSelection() {
        deleteSelected()
    }
    
    func deleteSelected(atPath: IndexPath? = nil) {
        
        var eventsToDelete = [IndexPath]()
        if atPath != nil {
            eventsToDelete = [atPath!]
        } else {
            eventsToDelete = self.selectedCellsPaths
        }
        
        let deleteAlert = UIAlertController(title: "Delete \(eventsToDelete.count) events?", message: nil, preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: { (deleteAlert)
            -> Void in
            
            for path in eventsToDelete {
                let eventToDelete = self.eventsFRC.object(at: path)
                self.stack.context.delete(eventToDelete)
            }

            self.save()
            self.selectedCellsPaths = [IndexPath]()
            
            self.tableView.reloadData()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (deleteAlert)
            -> Void in
            
        })
        
        deleteAlert.addAction(proceedAction)
        deleteAlert.addAction(cancelAction)
        
        // iPads have different requirements for AlertControllers!
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = deleteAlert.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = self.view
        }
        
        self.present(deleteAlert, animated: true, completion: nil)

    }
}

// MARK: - FetchedResultController functions


extension EventsListViewController: NSFetchedResultsControllerDelegate {
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        tableView.endUpdates()
        tableView.reloadData()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
}

