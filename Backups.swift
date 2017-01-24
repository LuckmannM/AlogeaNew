//
//  Backups.swift
//  Alogea
//
//  Created by mikeMBP on 23/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class Backups: UITableViewController {
    
    var localBackupsDirectoryPath : String? {
        
        return BackupController.localBackupDirectoryPath
    }
    
    var cloudBackupsDirectoryURL: NSURL? {
        
        return BackupController.cloudBackupsFolderURL
        
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
                    print("more than 10 backup directories, delete oldest")
                    self.deleteOldDirectories()
                }
                for file in files {
                    if file.contains("Backup") {
                        fileNames.append(file)
                    }
                }
            } catch let error as NSError {
                print("can't read local backup sub directories in main backup directory, error:  \(error)")
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
                    print("more than 10 backup directories, delete oldest")
                    self.deleteOldDirectories()
                }
                for url in fileURLs {
                    let fileName = (url.path as NSString).lastPathComponent
                    fileNames.append(fileName)
                }
            } catch let error as NSError {
                print("can't read cloud backup sub directories in main backup directory, error:  \(error)")
            }
        }
        return fileNames
        
    }
    
    var cloudButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backupActionButton  = UIBarButtonItem(title: "Backup now", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backupNow))
        
        self.hidesBottomBarWhenPushed = true
        self.tabBarController!.tabBar.isHidden = true
        
        cloudButton = UIButton(type: .custom)
        
        if FileManager.default.ubiquityIdentityToken != nil {
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

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if FileManager.default.ubiquityIdentityToken != nil {
            cloudButton.setImage(UIImage(named: "BlueCloud"), for: .disabled)
        } else {
            cloudButton.setImage(UIImage(named: "GreyCloud"), for: .disabled)
        }

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
            (cell.contentView.viewWithTag(40) as! UIButton).addTarget(self, action: #selector(startBackupFromLocal(sender:)), for: .touchUpInside)
        }
        else {
            // cloud backup files
            (cell.contentView.viewWithTag(10) as! UILabel).text = cloudBackupFiles[indexPath.row]
            (cell.contentView.viewWithTag(40) as! UIButton).addTarget(self, action: #selector(startBackupFromCloud(sender:)), for: .touchUpInside)
            
        }
        return cell
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
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    // MARK: - Button functions
    
    func startBackupFromLocal(sender: UIButton) {
        
        let originatingCell: UITableViewCell = sender.superview?.superview as! UITableViewCell // first superview is contentView
        let indexPath = tableView.indexPath(for: originatingCell)
        let backupFile = "/" + localBackupFiles[indexPath!.row]
        
        backupDialog(sender: sender, filePath: backupFile, fromLocalSource: true)
        
    }
    
    func startBackupFromCloud(sender: UIButton) {
        
        let originatingCell: UITableViewCell = sender.superview?.superview as! UITableViewCell // first superview is contentView
        let indexPath = tableView.indexPath(for: originatingCell)
        let backupFile = cloudBackupFiles[indexPath!.row]
        
        backupDialog(sender: sender, filePath: backupFile, fromLocalSource: false)
        
    }
    
    
    func backupDialog(sender: UIButton, filePath: String, fromLocalSource: Bool) {
        
        let backupDialog = UIAlertController(title: "Restore from backup", message: "Caution: this will replace all existing records with records from the saved backup! This cannot be reversed", preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Proceed", style: UIAlertActionStyle.default, handler: { (backupDialog)
            -> Void in
            
            BackupController.importFromBackup(folderName: filePath, fromLocalBackup: fromLocalSource)
            
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
        BackupController.BackupAllUserData()
        self.tableView.reloadData()
        
    }
    
    func deleteOldDirectories() {
        
        var folderURLs = [NSURL]()
        print("deleting backup folders, as there are more than ten")
        
        // check local backups folder
        repeat {
            // read backupFolders and count their number
            if localBackupsDirectoryPath != nil {
                do {
                    folderURLs = try  FileManager.default.contentsOfDirectory(at: NSURL(fileURLWithPath: localBackupsDirectoryPath!) as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) as [NSURL]
                } catch let error as NSError {
                    print("DataIO - deleteOldDirectories: can't read backup sub directories in main backup directory, error:  \(error)")
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
                        print("BackupController - deleteOldDirectories: can't read backup attributes/ creationDate, error:  \(error)")
                    }
                }
            }
            
            do {
                try FileManager.default.removeItem(atPath: fileToDeletePath)
            } catch let error as NSError {
                print("BackupController - deleteOldDirectories: can't delete oldest backup, error:  \(error)")
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
                    print("DataIO - deleteOldDirectories: can't read backup sub directories in main backup directory, error:  \(error)")
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
                        print("DataIO - deleteOldDirectories: can't read backup attributes/ creationDate, error:  \(error)")
                    }
                }
            }
            
            do {
                try FileManager.default.removeItem(atPath: fileToDeletePath)
            } catch let error as NSError {
                print("DataIO - deleteOldDirectories: can't delete oldest backup, error:  \(error)")
            }
            
        } while folderURLs.count > 10
    }
}
