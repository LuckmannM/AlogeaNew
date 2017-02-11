//
//  SettingsViewController.swift
//  Alogea
//
//  Created by mikeMBP on 14/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import UserNotifications

class SettingsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Class variables
    
    @IBOutlet weak var cloudSwitch: UISwitch!
    @IBOutlet weak var drugReminderSwitch: UISwitch!

    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    lazy var stack: CoreDataStack = {
        return (UIApplication.shared.delegate as! AppDelegate).stack
    }()
    
    lazy var recordTypesFRC : NSFetchedResultsController<RecordType> = {
        let request = NSFetchRequest<RecordType>(entityName: "RecordType")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        
        let fetch = NSFetchedResultsController<RecordType>(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetch.delegate = self
        return fetch
    }()
    
    var recordTypesController = RecordTypesController.sharedInstance()

    
    // MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.navigationController?.navigationBar.barTintColor = ColorScheme.sharedInstance().white
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 22)!, NSForegroundColorAttributeName: ColorScheme.sharedInstance().darkBlue]
        //self.navigationController?.navigationBar.tintColor = ColorScheme.sharedInstance().darkBlue
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.hidesBottomBarWhenPushed = false
        self.tabBarController!.tabBar.isHidden = false
        
        cloudSwitch.isOn = UserDefaults.standard.bool(forKey: iCloudBackUpsOn)
        print("MedReminders are set to \(UserDefaults.standard.bool(forKey: notification_MedRemindersOn))")
        drugReminderSwitch.isOn = UserDefaults.standard.bool(forKey: notification_MedRemindersOn)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom functions
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 
        switch section {
        case 0 :
            return 0
        case 1 :
            return 1
        case 2 :
            return 2
        case 3 :
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0 :
            return "Version " + (UIApplication.shared.delegate as! AppDelegate).appVersion + ", Build " + (UIApplication.shared.delegate as! AppDelegate).appBuild
        case 1 :
            return "Renaming and Deleting"
        case 2 :
            return "Backup and Restore options"
        case 3 :
            return "Medicine reminders"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        var textSize: CGFloat!
        
        textSize = 16 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width
        header.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: textSize)
        header.textLabel?.sizeToFit()
        
        header.textLabel?.textColor = ColorScheme.sharedInstance().darkBlue
    }

    
    func persistentStoreCoordinatorDidChangeStores(notification: NSNotification) {
        
        do {
            try recordTypesFRC.performFetch()
        } catch let error as NSError {
            print("Error fetching notes: \(error)")
        }
        
    }
    
    @IBAction func cloudSwitchAction(sender: UISwitch) {
        
        UserDefaults.standard.set(sender.isOn, forKey: iCloudBackUpsOn)
        
        if !sender.isOn {
            removeCloudBackupsDialog(sender: sender)
        } else {
            //check iCloud access available
            if FileManager.default.ubiquityIdentityToken == nil {
                showMissingfCloudAccessAlert(message: nil)
            } else {
                // first call establishes this container; only needs to be called once
                let _ = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            }
        }
        
    }
    
    func showMissingfCloudAccessAlert(message:String?) {
        
        let alertMessage = message ?? "There currently is no iCloud access. If you have not logged in, please do so at Settings > iCloud"
        
        let alertController = UIAlertController(title: title, message: alertMessage, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) -> Void in
            
        }))
        
        // Present Alert Controller
        self.present(alertController, animated: true, completion: nil)
        
    }

    
    func removeCloudBackupsDialog(sender: UISwitch) {
        
        let optionsDialog = UIAlertController(title: "Keep or delete all iCloud backups?", message: "When switching off iCloud storage you can keep existing Cloud backups for later access or delete them all now", preferredStyle: .actionSheet)
        
        let keepAction = UIAlertAction(title: "Keep backups", style: UIAlertActionStyle.default, handler: { (optionsDialog)
            -> Void in
            
            return
        })
        
        optionsDialog.addAction(keepAction)
        
        
        let deleteAction = UIAlertAction(title: "Delete all iCloud backups", style: .default, handler: { (exportDialog)
            -> Void in
            
            BackupController.deleteCloudBackups()
        })
        
        optionsDialog.addAction(deleteAction)
        
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = optionsDialog.popoverPresentationController
            popUpController!.permittedArrowDirections = .right
            popUpController?.sourceView = sender
            popUpController?.sourceRect = sender.bounds
        }
        
        
        self.present(optionsDialog, animated: true, completion: nil)
    }
    
    
    @IBAction func drugReminderSwitchAction(sender: UISwitch) {
        
        
        UserDefaults.standard.set(sender.isOn, forKey: notification_MedRemindersOn)
        
        print("MedReminders are set to \(UserDefaults.standard.bool(forKey: notification_MedRemindersOn))")

        // Switch off  - cancel all pending notifications for drugs
        if !sender.isOn {
            (UIApplication.shared.delegate as! AppDelegate).removeCategoryNotifications(withCategory: notification_MedReminderCategory)
            
        }
        else {
            // Switch on - recreate notifications for drugs that have reminders set
            let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
            var drugsList = [DrugEpisode]()
            
            do {
                drugsList = try managedObjectContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("SettingsVC_DrugReminderSwitchAction - error fetching drugList for reminderSWitch\(error)")
            }
            
            for drug in drugsList {
                // for some reason the iteration doesn't trigger awakeFromFetch for the drug object
                // the non-initiated local DrugEpisode variables can trigger crashes
                print("request notificationCheck for drug \(drug.nameVar)...")
                drug.convertFromStorage()
                drug.scheduleReminderNotifications(cancelExisting: false)
            }

        }
        
        // DEBUG
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: {
            (requests: [UNNotificationRequest]) in
            for request in requests {
                print("pending Notification: \(request)")
            }
        })
        
        // DEBUG
        
        
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "eventTypesSegue"
        {
            if let nextViewController = segue.destination as? EventTypeSettings {
                nextViewController.stack = stack
                nextViewController.rootViewController = self

            } else {
                print("error createNew segue: destinationViewcontrolle not defined")
            }
            
        }
    }
    
    
}

