//
//  Backups.swift
//  Alogea
//
//  Created by mikeMBP on 23/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications


class Backups: UITableViewController, UNUserNotificationCenterDelegate  {
    
    var localBackupsDirectoryPath : String? {
        
        return BackingUpController.localBackupsFolderPath
    }
    
    var cloudBackupsDirectoryURL: URL? {
        
        return BackingUpController.cloudBackupsFolderURL
        
    }
    
    var localBackupFiles: [String] {
        
        var fileNames = [String]()
        if localBackupsDirectoryPath != nil {
            
            // if folder empty or doesn't exist
            if !FileManager.default.fileExists(atPath: localBackupsDirectoryPath!) {
                return fileNames
            }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: localBackupsDirectoryPath!)
                if files.count == 0 { return fileNames }
                else if files.count > 10 {
                    self.deleteOldDirectories()
                }
                for file in files {
                    if file.contains("Backup") {
                        fileNames.append(file)
                    }
                }
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 1", showInVC: self, systemError: error, errorInfo: "can't read local backup sub directories in main backup directory")
            }
        }
        return fileNames
    }
    
    var cloudBackupFiles: [String] {
        
        var fileNames = [String]()
        if cloudBackupsDirectoryURL != nil {
            do {
                // if folder empty or doesn't exist
                if !FileManager.default.fileExists(atPath: (cloudBackupsDirectoryURL?.path)!) {
                    return fileNames
                }
                
                let fileURLs = try
                    FileManager.default.contentsOfDirectory(at: cloudBackupsDirectoryURL! as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                if fileURLs.count == 0 { return fileNames }
                else if fileURLs.count > 10 {
                    self.deleteOldDirectories()
                }
                for url in fileURLs {
                    let fileName = (url.path as NSString).lastPathComponent
                    fileNames.append(fileName)
                }
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 2", showInVC: self, systemError: error, errorInfo: "can't read cloud backup sub directories in main backup directory")
            }
        }
        return fileNames
        
    }
    
    var cloudButton: UIButton!
    var backupController: BackingUpController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backupActionButton  = UIBarButtonItem(title: "Backup now", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backupNow))
        
        self.hidesBottomBarWhenPushed = true
        self.tabBarController!.tabBar.isHidden = true
        
        cloudButton = UIButton(type: .custom)
        
        if FileManager.default.ubiquityIdentityToken == nil  {
            cloudButton.setImage(UIImage(named: "BlueCloud"), for: .disabled)
        } else {
            cloudButton.setImage(UIImage(named: "GreyCloud"), for: .disabled)
        }
        
        cloudButton.frame = CGRect(x: 0, y: 0, width: (75*20/50), height: 20)
        let cloudIcon = UIBarButtonItem(customView: cloudButton)
        cloudIcon.isEnabled = false
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = self.view.frame.width / 2 - cloudButton.frame.width / 2 - 100 // latter = estd. width of backupActionButton
        
        self.navigationItem.setRightBarButtonItems([backupActionButton, spacer, cloudIcon], animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(cloudBackupsUpdated), name: NSNotification.Name(rawValue: "CloudBackupFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMessage(notification:)), name: NSNotification.Name(rawValue: "Backup Complete"), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if DrugDictionary.sharedInstance().iCloudStatus == CKAccountStatus.available && InAppStore.sharedInstance().isConnectedToNetwork() == true {
            cloudButton.setImage(UIImage(named: "BlueCloud"), for: .disabled)
        } else {
            cloudButton.setImage(UIImage(named: "GreyCloud"), for: .disabled)
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    func cloudBackupsUpdated() {
        self.tableView.reloadSections([1], with: .automatic)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if localBackupFiles.count > 0 {
                return localBackupFiles.count
            } else {
                return 0
            }
        } else {
            if cloudBackupFiles.count > 0 {
                return cloudBackupFiles.count
            } else {
                return 0
            }
        }

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "backupCell", for: indexPath)
        
        if indexPath.section == 0 {
            // local backup files
            (cell.contentView.viewWithTag(10) as! UILabel).text = localBackupFiles[indexPath.row]
//            (cell.contentView.viewWithTag(40) as! UIButton).addTarget(self, action: #selector(startBackupFromLocal(sender:)), for: .touchUpInside)
        }
        else {
            // cloud backup files
            (cell.contentView.viewWithTag(10) as! UILabel).text = cloudBackupFiles[indexPath.row]
//            (cell.contentView.viewWithTag(40) as! UIButton).addTarget(self, action: #selector(startBackupFromCloud(sender:)), for: .touchUpInside)
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            backupFromLocal(path: indexPath)
        } else {
            backupFromCloud(path: indexPath)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
        if section == 0 {
            return "Backups on this device"
        } else {
            if UserDefaults.standard.bool(forKey: iCloudBackUpsOn) {
                return "Backups in iCloud (on)"
            } else {
                return "Backups in iCloud (off)"
            }
        }
    }
    // MARK: - Button functions
    
//    func startBackupFromLocal(sender: UIButton) {
//        
//        let originatingCell: UITableViewCell = sender.superview?.superview as! UITableViewCell // first superview is contentView
//        let indexPath = tableView.indexPath(for: originatingCell)
//        let backupFile = "/" + localBackupFiles[indexPath!.row]
//        
//        backupDialog(sender: sender, filePath: backupFile, fromLocalSource: true)
//        
//    }
//    
//    func startBackupFromCloud(sender: UIButton) {
//        
//        let originatingCell: UITableViewCell = sender.superview?.superview as! UITableViewCell // first superview is contentView
//        let indexPath = tableView.indexPath(for: originatingCell)
//        let backupFile = cloudBackupFiles[indexPath!.row]
//        
//        backupDialog(sender: sender, filePath: backupFile, fromLocalSource: false)
//        
//    }
    
    // MARK: - CellRowFunctions instead
    
    func backupFromLocal(path: IndexPath) {
        
        let originatingCell = tableView.cellForRow(at: path)
        let backupFile = "/" + localBackupFiles[path.row]
        
        backupDialog(sender: originatingCell!, filePath: backupFile, fromLocalSource: true)
        
    }
    
    func backupFromCloud(path: IndexPath) {
        
        let originatingCell = tableView.cellForRow(at: path)
        let backupFile = "/" + cloudBackupFiles[path.row]
        
        backupDialog(sender: originatingCell!, filePath: backupFile, fromLocalSource: false)
        
    }


    
    
    func backupDialog(sender: UITableViewCell, filePath: String, fromLocalSource: Bool) {
        
        let backupDialog = UIAlertController(title: "Restore from backup", message: "Caution: this will replace all existing records with records from the saved backup! This cannot be reversed", preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Proceed", style: UIAlertActionStyle.default, handler: { (backupDialog)
            -> Void in
            
            if fromLocalSource {
                BackingUpController.startRestoreFromLocalBackup(fromFolder: filePath)
            } else {
                BackingUpController.startRestoreFromCloudBackup(fromFolder: filePath)
            }
            
        })
        
        backupDialog.addAction(proceedAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (backupDialog)
            -> Void in
            
            return
            
        })
        
        backupDialog.addAction(cancelAction)
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = backupDialog.popoverPresentationController
            popUpController!.permittedArrowDirections = .up
            popUpController?.sourceView = sender
            popUpController?.sourceRect = sender.bounds
        }
        
        
        self.present(backupDialog, animated: true, completion: nil)
        
    }
    
    func backupNow() {
        BackingUpController.BackupAllData()
        self.tableView.reloadData()
        
    }
    
    func deleteOldDirectories() {
        
        var folderURLs = [NSURL]()
        // check local backups folder
        repeat {
            // read backupFolders and count their number
            if localBackupsDirectoryPath != nil {
                do {
                    folderURLs = try  FileManager.default.contentsOfDirectory(at: NSURL(fileURLWithPath: localBackupsDirectoryPath!) as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) as [NSURL]
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 3", showInVC: self, systemError: error, errorInfo:"deleteOldDirectories: can't read backup sub directories in main backup directory")
                }
            }
            
            var earliestDate = NSDate()
            var fileToDeletePath = String()
            
            // go through all folders, determine their creationDate, find the oldest and remove this
            // then repeat until folder number <= 10
            for url in folderURLs {
                if let folderPath = url.path {
                    do {
                        let folderCreationDate =  try FileManager.default.attributesOfItem(atPath: folderPath)[FileAttributeKey.creationDate] as! NSDate
                        if earliestDate.earlierDate(folderCreationDate as Date) == folderCreationDate as Date {
                            fileToDeletePath = folderPath
                            earliestDate = folderCreationDate
                        }
                        
                    } catch let error as NSError {
                        ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 4", showInVC: self, systemError: error, errorInfo:"deleteOldDirectories: can't read backup attributes/ creationDate")
                    }
                }
            }
            
            do {
                try FileManager.default.removeItem(atPath: fileToDeletePath)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 5", showInVC: self, systemError: error)
            }
            
        } while folderURLs.count > 10
        
        // if on and available check cloud backups folder
        
        if FileManager.default.ubiquityIdentityToken == nil || !UserDefaults.standard.bool(forKey: iCloudBackUpsOn) {
            return
        }
        
        folderURLs.removeAll()
        
        repeat {
            // read backupFolders and count their number
            if cloudBackupsDirectoryURL != nil {
                do {
                    folderURLs = try FileManager.default.contentsOfDirectory(at: cloudBackupsDirectoryURL! as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) as [NSURL]
                    if folderURLs.count <= 10 { return }
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 6", showInVC: self, systemError: error, errorInfo: "deleteOldDirectories: can't read backup sub directories in main backup directory")
                }
            }
            
            var earliestDate = NSDate()
            var fileToDeletePath = String()
            
            // go through all folders, determine their creationDate, find the oldest and remove this
            // then repeat until folder number <= 10
            for url in folderURLs {
                if let folderPath = url.path {
                    do {
                        let folderCreationDate =  try FileManager.default.attributesOfItem(atPath: folderPath)[FileAttributeKey.creationDate] as! NSDate
                        if earliestDate.earlierDate(folderCreationDate as Date) == folderCreationDate as Date {
                            fileToDeletePath = folderPath
                            earliestDate = folderCreationDate
                        }
                        
                    } catch let error as NSError {
                        ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 7", showInVC: self, systemError: error, errorInfo: "deleteOldDirectories: can't read backup attributes/ creationDate")
                    }
                }
            }
            
            do {
                try FileManager.default.removeItem(atPath: fileToDeletePath)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupVC Error 8", showInVC: self, systemError: error, errorInfo:"deleteOldDirectories: can't delete oldest backup")
            }
            
        } while folderURLs.count > 10
    }
    
    // MARK: - MEssage dailog
    
    func showMessage(notification: Notification) {
        
        let presentingVC = self
        let titleToUse = notification.name
        let messageToUse = (notification.userInfo?["text"])! as! String
        
        let alertController = UIAlertController(title: titleToUse.rawValue, message: messageToUse, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
            
        }))
        
        // Present Alert Controller
        presentingVC.present(alertController, animated: true, completion: nil)
        
    }
  
    
}
