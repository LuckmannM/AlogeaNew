//
//  BackingupController.swift
//  Alogea
//
//  Created by mikeMBP on 23/02/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import NotificationCenter

protocol BackingUpControllerDelegate {
    
    func iCloudBackupComplete()
    
}

class BackingUpController {
    
    var delegate:BackingUpControllerDelegate!
    
    static let evenstFileName = "/EventsDictionary"
    static let drugsFileName = "/DrugsDictionary"
    static let recordTypesFileName = "/RecordTypesDictionary"

    static let localBackupsFolderName = "/Backups" // this is the top folder containg all dated local backup folders
    static let cloudBackupsFolderName = "/\(UIDevice.current.name) CloudBackups" // this is the basic name component for each dated cloudBackup folder
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    // MARK: - top folder paths
    
    static var applicationSupportDirectoryPath: String? = {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        if paths.count > 0 {
            if FileManager.default.fileExists(atPath: paths[0]) {
                return paths[0]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }()
    
    static var localBackupsFolderPath: String? = {
        // the path to the folder 'Library/ApplicationSupport/Backups'
        guard let appSupportDirectoryPath = applicationSupportDirectoryPath else {
            return nil
        }
        
        return appSupportDirectoryPath.appending(localBackupsFolderName)
    }()
    
    static var cloudStorageURL: URL? = {
        // the URL to the general iCloud storage. url(forUbiquityContainerIdentifier:) should be called once before accessing folders
        
        if FileManager.default.ubiquityIdentityToken == nil {
            return nil
        }
        
        var iCloudStorageURL: URL?
        
        DispatchQueue.main.async() {
            iCloudStorageURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        }
        
        return iCloudStorageURL
        
    }()
    
    static var cloudBackupsFolderURL: URL? = {
        // the URL for specific iCloud Backups folder based on the above general iLCouod storage url
        var cloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(cloudBackupsFolderName)
        if cloudURL == nil {
            do {
                try FileManager.default.createDirectory(at: (cloudStorageURL?.appendingPathComponent(cloudBackupsFolderName))!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 0", systemError: error, errorInfo: "Can't create iCloud toplevel Backups folder")
            }
        }
        
        return cloudURL
    }()
    
    // MARK: - FetchRequests for ManagedObjects
    static var recordTypes:[RecordType] {
        var array: [RecordType]! // RecordType events are events that are drawn in graphView
        let fetchRequest = NSFetchRequest<RecordType>(entityName: "RecordType")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            array = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 1", systemError: error)
        }
        return array
    }
    
    static var events:[Event] {
        var array: [Event]! // RecordType events are events that are drawn in graphView
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            array = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 2", systemError: error)
        }
        return array
    }
    
    static var drugs:[DrugEpisode] {
        var array: [DrugEpisode]! // RecordType events are events that are drawn in graphView
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            array = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 3", systemError: error)
        }
        return array
    }
    
    class func BackupAllData() {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "d.M.YY"
            return formatter
        }()
        
        // create Dictionary data objects
        let eventsData = createEventsDictionary()
        let drugsData = createDrugsDictionary()
        let recordTypesData = createRecordTypesDictionary()
        
        // check whether local dated Backup folder already exists; if so delete nad create, otherwise create new
        
        guard localBackupsFolderPath != nil else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 4; can't save Backup", errorInfo:"error - cannot find directory at /Library/ApplicationSupport/Backups")
            return
        }

        let newFolderName = "/Backup " + dateFormatter.string(from: Date())
        let newFolderPath = localBackupsFolderPath!.appending(newFolderName)
        
        // 1. if a folder with todays date  already exists delete it
        if FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.removeItem(atPath: newFolderPath)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 5", systemError: error, errorInfo: "can't delete existing Backup Folder to create replacement at path \(newFolderPath)")
            }
        }
        // 2. create new Backup folder with current date
        do {
            try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 6", systemError: error, errorInfo: "Can't create new Backup Folder at path \(newFolderPath)")
            return
        }
        
        fileIO(backupFolderPath: newFolderPath, fileName: evenstFileName, data: eventsData, cloud: false)
        fileIO(backupFolderPath: newFolderPath, fileName: drugsFileName, data: drugsData, cloud: false)
        fileIO(backupFolderPath: newFolderPath, fileName: recordTypesFileName, data: recordTypesData, cloud: false)
        
        
        if UserDefaults.standard.bool(forKey: iCloudBackUpsOn) {
            CloudBackups(fromBackupFolderPath: newFolderPath)
        }
    }
    
    static func CloudBackups(fromBackupFolderPath: String) {
        
        if FileManager.default.ubiquityIdentityToken == nil {
            ErrorManager.sharedInstance().errorMessage(title: "iCloud currently not accessible", message: "iCloud backup can't be saved")
            return
        }

        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "d.M.YY"
            return formatter
        }()

        let tempFolderPath = localBackupsFolderPath?.appending("/Temp")

        if FileManager.default.fileExists(atPath: tempFolderPath!) {
            // 0. remove any folder 'Temp' otherwise step 1 fails
            do {
                try FileManager.default.removeItem(atPath: tempFolderPath!)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 6.1", systemError: error, errorInfo: "Can't remove current temp Backup Folder at path \(tempFolderPath) before copying current backup to temp")
                return
            }
        }

        // 1. create a copy folder 'Temp' odf the current local backups folder
        do {
            try FileManager.default.copyItem(atPath: fromBackupFolderPath, toPath: tempFolderPath!)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 7", systemError: error, errorInfo: "Can't copy current Backup Folder at path \(fromBackupFolderPath) to temp backfolder for iCloud backup")
            return
        }
        
        // *** DEBUG
        do {
            let filesInBckupFolder = try FileManager.default.contentsOfDirectory(atPath: localBackupsFolderPath!)
            print("files contained in \(localBackupsFolderPath!) are ...")
            for file in filesInBckupFolder {
                print("...\(file)")
            }
        }
        catch let error as NSError {
            print("Filemanager reported error when getting contents of folder \(localBackupsFolderPath): error is \(error)")
        }
        print("tempFile exists? \(FileManager.default.fileExists(atPath: tempFolderPath!))")
        // *** DEBUG
        
        // 2.  create new folder in toplevel iCloud Backups folder
        let newCloudFolder = cloudBackupsFolderURL?.appendingPathComponent("CloudBackup " + dateFormatter.string(from: Date()), isDirectory: true)
//        do {
//            try FileManager.default.createDirectory(at: newCloudFolder!, withIntermediateDirectories: true, attributes: nil)
//        } catch let error as NSError {
//            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 7.1", systemError: error, errorInfo: "Can't create new empty Backup Folder in iCloud at path \(newCloudFolder)")
//            return
//        }
        if FileManager.default.fileExists(atPath: newCloudFolder!.path) {
            // 0. remove any folder 'Temp' otherwise step 1 fails
            do {
                try FileManager.default.removeItem(atPath: newCloudFolder!.path)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 7.1", systemError: error, errorInfo: "Can't remove current iCLoud Backup Folder at path \(newCloudFolder)")
                return
            }
        }

        
        
        // 3.  move files in this folder to iCloud storage
        let localTempFolderURL = URL(fileURLWithPath: tempFolderPath!)
        
        // *** Look at completion handler for async qeue as in DrugDictionary to refresh Backups.tableView and delete Temp folder
        DispatchQueue.main.async {
            do {
                // this does the actual copying to iCloud
                try  FileManager.default.setUbiquitous(true, itemAt: localTempFolderURL, destinationURL: newCloudFolder!)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 8", systemError: error, errorInfo:"error writing Backups directory to iCloud documents")
            }
            // refresh Backups.tableview data here
            // send as notification
            NotificationCenter.default.post(name: Notification.Name(rawValue:"CloudBackupFinished"), object: nil)
        }
        
    }
    
    static func fileIO(backupFolderPath: String, fileName: String, data: Data, cloud: Bool) {
        
        let fileURL = NSURL(fileURLWithPath: (backupFolderPath.appending(fileName)))
        
        // write data to file
        do {
            if cloud {
                try data.write(to: fileURL as URL, options: [.atomic]) // file not encrypted for iCloud
            } else {
                try data.write(to: fileURL as URL, options: [.completeFileProtectionUnlessOpen, .atomic]) // file encrypted for local
            }
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 7", systemError: error, errorInfo:"error trying to write and encrypt file at \(fileURL)")
        }
    }
    

    
    
    // MARK: - creating individual Dictionaries to write to file
    
    static func createEventsDictionary() -> Data {
        
        var eventsDictionaryArray = [NSDictionary]()
        
        for object in events {
            let event = object as Event
            var singleEventDictionary: Dictionary = [String : NSData]()
            
            singleEventDictionary["name"] = NSKeyedArchiver.archivedData(withRootObject: event.name!) as NSData
            singleEventDictionary["date"] = NSKeyedArchiver.archivedData(withRootObject: event.date!) as NSData
            if event.type != nil {
                singleEventDictionary["type"] = NSKeyedArchiver.archivedData(withRootObject: event.type!) as NSData
            }
            if event.duration != nil {
                singleEventDictionary["duration"] = NSKeyedArchiver.archivedData(withRootObject: event.duration) as NSData
            }
            singleEventDictionary["vas"] = NSKeyedArchiver.archivedData(withRootObject: event.vas) as NSData
            if event.outcome != nil {
                singleEventDictionary["outcome"] = NSKeyedArchiver.archivedData(withRootObject: event.outcome!) as NSData
            }
            if event.bodyLocation != nil {
                singleEventDictionary["location"] = NSKeyedArchiver.archivedData(withRootObject: event.bodyLocation!) as NSData
            }
            if event.locationImage != nil {
                singleEventDictionary["locationImage"] = NSKeyedArchiver.archivedData(withRootObject: event.locationImage!) as NSData
            }
            if event.note != nil {
                singleEventDictionary["note"] = NSKeyedArchiver.archivedData(withRootObject: event.note!) as NSData
            }
            
            eventsDictionaryArray.append(singleEventDictionary as NSDictionary)
        }
        return NSKeyedArchiver.archivedData(withRootObject: eventsDictionaryArray)
    }
    
    static func createDrugsDictionary() -> Data {
        
        var drugsDictionaryArray = [NSDictionary]()
        
        for object in drugs {
            let drug = object as DrugEpisode
            var singleDrugDictionary: Dictionary = [String : NSData]()
            
            singleDrugDictionary["name"] = NSKeyedArchiver.archivedData(withRootObject: drug.name!) as NSData
            singleDrugDictionary["startDate"] = NSKeyedArchiver.archivedData(withRootObject: drug.startDate!) as NSData
            singleDrugDictionary["drugID"] = NSKeyedArchiver.archivedData(withRootObject: drug.drugID!) as NSData
            singleDrugDictionary["doses"] = NSKeyedArchiver.archivedData(withRootObject: drug.doses!) as NSData
            singleDrugDictionary["doseUnit"] = NSKeyedArchiver.archivedData(withRootObject: drug.doseUnit!) as NSData
            singleDrugDictionary["regularly"] = NSKeyedArchiver.archivedData(withRootObject: drug.regularly) as NSData
            singleDrugDictionary["reminders"] = NSKeyedArchiver.archivedData(withRootObject: drug.reminders!) as NSData
            singleDrugDictionary["isCurrent"] = NSKeyedArchiver.archivedData(withRootObject: drug.isCurrent!) as NSData
            singleDrugDictionary["frequency"] = NSKeyedArchiver.archivedData(withRootObject: drug.frequency) as NSData
            
            
            if drug.ingredients != nil {
                singleDrugDictionary["ingredients"] = NSKeyedArchiver.archivedData(withRootObject: drug.ingredients!) as NSData
            }
            if drug.classes != nil {
                singleDrugDictionary["classes"] = NSKeyedArchiver.archivedData(withRootObject: drug.classes!) as NSData
            }
            if drug.endDate != nil {
                singleDrugDictionary["endDate"] = NSKeyedArchiver.archivedData(withRootObject: drug.endDate!) as NSData
            }
            if drug.effectiveness != nil {
                singleDrugDictionary["effectiveness"] = NSKeyedArchiver.archivedData(withRootObject: drug.effectiveness!) as NSData
            }
            if drug.sideEffects != nil {
                singleDrugDictionary["sideEffects"] = NSKeyedArchiver.archivedData(withRootObject: drug.sideEffects!) as NSData
            }
            if drug.notes != nil {
                singleDrugDictionary["notes"] = NSKeyedArchiver.archivedData(withRootObject: drug.notes!) as NSData
            }
            if drug.attribute1 != nil {
                singleDrugDictionary["attribute1"] = NSKeyedArchiver.archivedData(withRootObject: drug.attribute1!) as NSData
            }
            if drug.attribute2 != nil {
                singleDrugDictionary["attribute2"] = NSKeyedArchiver.archivedData(withRootObject: drug.attribute2!) as NSData
            }
            if drug.attribute3 != nil {
                singleDrugDictionary["attribute3"] = NSKeyedArchiver.archivedData(withRootObject: drug.attribute3!) as NSData
            }
            
            drugsDictionaryArray.append(singleDrugDictionary as NSDictionary)
        }
        return NSKeyedArchiver.archivedData(withRootObject: drugsDictionaryArray)
        
    }
    
    static func createRecordTypesDictionary() -> Data {
        
        var recordTypesDictionaryArray = [NSDictionary]()
        
        for object in recordTypes {
            let type = object as RecordType
            var singleTypeDictionary: Dictionary = [String : NSData]()
            
            if type.name != nil { singleTypeDictionary["name"] = NSKeyedArchiver.archivedData(withRootObject: type.name!) as NSData }
            if type.dateCreated != nil { singleTypeDictionary["date"] = NSKeyedArchiver.archivedData(withRootObject: type.dateCreated!) as NSData }
            if type.maxScore != nil {
                singleTypeDictionary["maxScore"] = NSKeyedArchiver.archivedData(withRootObject: type.maxScore) as NSData
            }
            if type.minScore != nil {
                singleTypeDictionary["minScore"] = NSKeyedArchiver.archivedData(withRootObject: type.minScore) as NSData
            }
            
            recordTypesDictionaryArray.append(singleTypeDictionary as NSDictionary)
            
        }
        return NSKeyedArchiver.archivedData(withRootObject: recordTypesDictionaryArray)
    }


}
