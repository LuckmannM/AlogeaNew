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
    
    static let eventsFileName = "/EventsDictionary"
    static let drugsFileName = "/DrugsDictionary"
    static let recordTypesFileName = "/RecordTypesDictionary"

    static let localBackupsFolderName = "/Backups" // this is the top folder containg all dated local backup folders
    static let cloudBackupsFolderName = "\(UIDevice.current.name) CloudBackups" // this is the basic name component for each dated cloudBackup folder
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
//    init() {
//        NotificationCenter.default.addObserver(self, selector: #selector(updateCloudAccess), name: NSNotification.Name(rawValue: "UpdateCloudAccess"), object: nil)
//    }
    
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
        //print("local Backups at: \(appSupportDirectoryPath.appending(localBackupsFolderName))")
        
        return appSupportDirectoryPath.appending(localBackupsFolderName)
    }()
    
    static var cloudStorageURL: URL?  = {
        // the URL to the general iCloud storage. url(forUbiquityContainerIdentifier:) should be called once before accessing folders
        
        if FileManager.default.ubiquityIdentityToken == nil {
            return nil
        }
        
        var iCloudStorageURL: URL?
        
        DispatchQueue.main.async() {
            iCloudStorageURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            updateCloudAccess(cloudURL: iCloudStorageURL)
        }
        
        return iCloudStorageURL
    }()
    
    static func updateCloudAccess(cloudURL: URL?) {
        
        guard cloudURL != nil  else {
            return
        }
        
        cloudStorageURL = cloudURL
        cloudBackupsFolderURL = updateCloudBackupsFolderURL()
        // the next updates the Backups VC Cloud Backup section
        NotificationCenter.default.post(name: Notification.Name(rawValue:"CloudBackupFinished"), object: nil)
    }
    

    static var cloudBackupsFolderURL: URL? = {
        // the URL for toplevel iCloud Backups folder based on the above general iClouod storage url
        // on first init this often is nil as the underlying cloudStorageURL takes some time to be made available (async queue)
        // as soon as cloudStorageURL is ready the 'updateCloudAccess' function is called which updates cloudStorageURL
        // tnhis in turn calls 'updateCloudBackupsFolderURL' which updates cloudBackupsFolderURL
        
        guard cloudStorageURL != nil  else {
            return nil
        }
        
        if let cloudFolderURL = cloudStorageURL?.appendingPathComponent(cloudBackupsFolderName) {
            if !FileManager.default.fileExists(atPath: cloudFolderURL.path) {
                do {
                    try FileManager.default.createDirectory(at: cloudFolderURL, withIntermediateDirectories: false, attributes: nil)
                    return cloudFolderURL
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "Backup failed with error 0.1", systemError: error, errorInfo: "Can't create iCloud toplevel Backups folder")
                }
            }
        }
        return nil
    }()
    
    static func updateCloudBackupsFolderURL() -> URL? {
        
        guard cloudStorageURL != nil  else {
            return nil
        }
        
        if let cloudFolderURL = cloudStorageURL?.appendingPathComponent(cloudBackupsFolderName) {
            //print("got Folder path containing Cloud Backups: \(cloudFolderURL.path)")
            if !FileManager.default.fileExists(atPath: cloudFolderURL.path) {
                do {
                    try FileManager.default.createDirectory(at: cloudFolderURL, withIntermediateDirectories: false, attributes: nil)
                    return cloudFolderURL
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 0.2", systemError: error, errorInfo: "Can't create iCloud toplevel Backups folder")
                }
            } else {
                return cloudFolderURL
            }
        }
        return nil
    }
    
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
    
    
    // MARK: - Creating and writing backups
    
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
            ErrorManager.sharedInstance().errorMessage(message: "BackupController failed with error 4; can't save Backup", errorInfo:"error - cannot find directory at /Library/ApplicationSupport/Backups")
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
        
        fileIO(backupFolderPath: newFolderPath, fileName: eventsFileName, data: eventsData, encrypted: true)
        fileIO(backupFolderPath: newFolderPath, fileName: drugsFileName, data: drugsData, encrypted: true)
        fileIO(backupFolderPath: newFolderPath, fileName: recordTypesFileName, data: recordTypesData, encrypted: true)
        
        
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

        guard let tempFolderPath = localBackupsFolderPath?.appending("/Temp") else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 7", errorInfo: "Can't create new Temp Folder in local directory \(localBackupsFolderPath)")
            return
        }

        if FileManager.default.fileExists(atPath: tempFolderPath) {
            // 0. remove any folder 'Temp' otherwise step 1 fails
            do {
                try FileManager.default.removeItem(atPath: tempFolderPath)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 8", systemError: error, errorInfo: "Can't remove current temp Backup Folder at path \(tempFolderPath) before copying current backup to temp")
                return
            }
        }

        // 1. create a copy folder 'Temp' of the current local backups folder
        do {
            try FileManager.default.copyItem(atPath: fromBackupFolderPath, toPath: tempFolderPath)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 9", systemError: error, errorInfo: "Can't copy current Backup Folder at path \(fromBackupFolderPath) to temp backfolder for iCloud backup")
            return
        }
        
        // 2.  create new folder in toplevel iCloud Backups folder
        //print("cloudStorageURL = \(cloudStorageURL)")
        //print("cloudBackupsURL = \(updateCloudBackupsFolderURL())")
        guard let newCloudFolder = cloudBackupsFolderURL?.appendingPathComponent("CloudBackup " + dateFormatter.string(from: Date()), isDirectory: true) else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 10", errorInfo: "Can't create new CloudBackup Folder in directory \(cloudBackupsFolderURL)")
            return
        }
        
        if FileManager.default.fileExists(atPath: newCloudFolder.path) {
            // check if alredy exists and remove any folder 'Temp' otherwise step 3 fails
            do {
                try FileManager.default.removeItem(atPath: newCloudFolder.path)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 11", systemError: error, errorInfo: "Can't remove current iCLoud Backup Folder at path \(newCloudFolder)")
                return
            }
        }

        // 3.  move files in this folder to iCloud storage
        let localTempFolderURL = URL(fileURLWithPath: tempFolderPath)
        DispatchQueue.main.async {
            do {
                // this does the actual copying to iCloud
                try  FileManager.default.setUbiquitous(true, itemAt: localTempFolderURL, destinationURL: newCloudFolder)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 13", systemError: error, errorInfo:"error moving temp Backup directory at \(localTempFolderURL)to iCloud at \(newCloudFolder)")
            }
            // refresh Backups.tableview data when ready
            NotificationCenter.default.post(name: Notification.Name(rawValue:"CloudBackupFinished"), object: nil)
        }
        
    }
    
    static func fileIO(backupFolderPath: String, fileName: String, data: Data, encrypted: Bool) {
        
        let fileURL = NSURL(fileURLWithPath: (backupFolderPath.appending(fileName)))
        
        // write data to file
        do {
            if !encrypted {
                try data.write(to: fileURL as URL, options: [.atomic]) // file not encrypted for iCloud
            } else {
                try data.write(to: fileURL as URL, options: [.completeFileProtectionUnlessOpen, .atomic]) // file encrypted for local
            }
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 14", systemError: error, errorInfo:"error trying to write and encrypt file at \(fileURL)")
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
                singleEventDictionary["duration"] = NSKeyedArchiver.archivedData(withRootObject: event.duration!) as NSData
            }
            if event.vas != nil {
                singleEventDictionary["vas"] = NSKeyedArchiver.archivedData(withRootObject: event.vas!) as NSData
            }
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
            if event.urid != nil {
                singleEventDictionary["urid"] = NSKeyedArchiver.archivedData(withRootObject: event.urid!) as NSData
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
            if drug.urid != nil {
                singleDrugDictionary["urid"] = NSKeyedArchiver.archivedData(withRootObject: drug.urid!) as NSData
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
                singleTypeDictionary["maxScore"] = NSKeyedArchiver.archivedData(withRootObject: type.maxScore!) as NSData
            }
            if type.minScore != nil {
                singleTypeDictionary["minScore"] = NSKeyedArchiver.archivedData(withRootObject: type.minScore!) as NSData
            }
            if type.urid != nil {
                singleTypeDictionary["urid"] = NSKeyedArchiver.archivedData(withRootObject: type.urid!) as NSData
            }
            
            recordTypesDictionaryArray.append(singleTypeDictionary as NSDictionary)
            
        }
        return NSKeyedArchiver.archivedData(withRootObject: recordTypesDictionaryArray)
    }
    
    // MARK: - restoring from Backups
    
    static func startRestoreFromLocalBackup(fromFolder: String) {
        importFromBackup(sourcePath: (localBackupsFolderPath?.appending(fromFolder)))
    }
    
    static func startRestoreFromCloudBackup(fromFolder: String) {
        //downLoadCloudBackup(atPath: fromFolder)
        let cloudFolderPath = cloudBackupsFolderURL?.path.appending(fromFolder)
        importFromBackup(sourcePath: cloudFolderPath)
    }
    
    static func importFromBackup(sourcePath: String?) {
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        var restoreError = false
        
        if sourcePath != nil {
            
// 1. Events
            if let dict = dataFilesToDictionaries(filePath: sourcePath!, dictionaryType:eventsFileName) {
                let eventsDictionaryArray = dict as [NSDictionary]
                deleteAllEvents()
                
                for eventDictionary in eventsDictionaryArray {
                    
                    let newEvent:Event? = {
                        NSEntityDescription.insertNewObject(forEntityName: "Event", into: moc) as? Event
                    }()
                    
                    if newEvent != nil {
                        
                        for keyObject in eventDictionary.allKeys {
                            let key = keyObject as! String
                            
                            switch key {
                            case  "name":
                                newEvent!.name = (NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["name"] as! Data)) as! String)
                            case  "type":
                                newEvent!.type = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["type"] as! Data)) as? String
                            case "date":
                                newEvent!.date = (NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["date"] as! Data)) as! NSDate)
                            case "vas":
                                newEvent!.vas = (NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["vas"] as! Data)) as? NSNumber)
                            case "duration":
                                newEvent!.duration = (NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["duration"] as! Data)) as? NSNumber)
                            case "location":
                                newEvent!.bodyLocation = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["location"] as! Data)) as? String
                            case "note":
                                newEvent!.note = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["note"] as! Data)) as? String
                            case "outcome":
                                newEvent!.outcome = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["outcome"] as! Data)) as? String
                            case "locationImage":
                                newEvent!.locationImage = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["locationImage"]as! Data)) as? NSObject
                            case "urid":
                                newEvent!.urid = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["urid"]as! Data)) as? String

                            default:
                                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 15", errorInfo:"backup event dictionary unrecognised key \(key)")
                            }
                            
                        }
                        
                        // data QC
                        // ensure essential data is present, otherwise delete/don't import
                        if newEvent?.name == nil || newEvent?.name == "" {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all events were imported successfully", errorInfo:"some errors in imported event sets: event.name == nil")
                            moc.delete(newEvent!)
                        } else if newEvent?.type == nil || newEvent?.type == "" {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all events were imported successfully", errorInfo:"some errors in imported event sets: event.type == nil")
                            moc.delete(newEvent!)
                        } else if newEvent?.date == nil {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all events were imported successfully", errorInfo:"some errors in imported event sets: event.date == nil")
                            moc.delete(newEvent!)
                        }
                    }
                }
            } else {
                // ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 16", errorInfo:"can't import EventsBackup into dictionary array in 'importFramBackup'; filepath is \(sourcePath)")
                ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 16", systemError: nil, errorInfo: "can't import EventsBackup into dictionary array in 'importFramBackup'; filepath is \(sourcePath)")
                restoreError = true
            }
            
// 2. Drugs
            if let dict = dataFilesToDictionaries(filePath: sourcePath!, dictionaryType: drugsFileName) {
                let drugsDictionaryArray = dict as [NSDictionary]
                deleteAllDrugs()
                
                for drugDictionary in drugsDictionaryArray {
                    
                    let newDrugEpsiode:DrugEpisode? = {
                        NSEntityDescription.insertNewObject(forEntityName: "DrugEpisode", into: moc) as? DrugEpisode
                    }()
                    
                    if newDrugEpsiode != nil {
                        
                        for keyObject in drugDictionary.allKeys {
                            let key = keyObject as! String
                            
                            switch key {
                            case  "name":
                                newDrugEpsiode!.name = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["name"] as! Data)) as! String)
                            case  "drugID":
                                newDrugEpsiode!.drugID = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["drugID"] as! Data)) as! String)
                            case  "isCurrent":
                                newDrugEpsiode!.isCurrent = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["isCurrent"] as! Data)) as! String)
                            case  "startDate":
                                newDrugEpsiode!.startDate = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["startDate"] as! Data)) as! NSDate)
                            case "doses":
                                newDrugEpsiode!.doses = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["doses"] as! Data)) as! NSData)
                            case "doseUnit":
                                newDrugEpsiode!.doseUnit = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["doseUnit"] as! Data)) as! String)
                            case "frequency":
                                newDrugEpsiode!.frequency = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["frequency"] as! Data)) as! Double
                            case "regularly":
                                newDrugEpsiode!.regularly = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["regularly"] as! Data)) as! Bool
                            case "endDate":
                                newDrugEpsiode!.endDate = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["endDate"] as! Data)) as? NSDate
                            case "classes":
                                newDrugEpsiode!.classes = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["classes"] as! Data)) as? NSData
                            case "ingredients":
                                newDrugEpsiode!.ingredients = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["ingredients"] as! Data)) as? NSData
                            case "effectiveness":
                                newDrugEpsiode!.effectiveness = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["effectiveness"] as! Data)) as? String
                            case "sideEffects":
                                newDrugEpsiode!.sideEffects = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["sideEffects"] as! Data)) as? NSData
                            case "notes":
                                newDrugEpsiode!.notes = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["notes"] as! Data)) as? String
                            case "reminders":
                                newDrugEpsiode!.reminders = (NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["reminders"] as! Data)) as! NSData)
                            case "attribute1":
                                newDrugEpsiode!.attribute1 = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["attribute1"] as! Data)) as? NSData
                            case "attribute2":
                                newDrugEpsiode!.attribute2 = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["attribute2"] as! Data)) as? NSData
                            case "attribute3":
                                newDrugEpsiode!.attribute3 = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["attribute3"] as! Data)) as? NSData
                            case "urid":
                                newDrugEpsiode!.urid = NSKeyedUnarchiver.unarchiveObject(with: (drugDictionary["urid"]as! Data)) as? String
                            default:
                                print("backup drug dictionary unrecognised key \(key)")
                                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 17")
                            }
                            
                        }
                        
                        newDrugEpsiode?.awakeFromFetch()
                        
                        // data QC
                        // ensure essential data is present, otherwise delete/don't import
                        if newDrugEpsiode?.name == nil || newDrugEpsiode?.name == "" {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.name == nil")
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.drugID == nil || newDrugEpsiode?.drugID == "" {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.drugID == nil")
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.startDate == nil {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.startDate == nil")
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.doses == nil {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.doses == nil")
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.doseUnit == nil {
                            moc.delete(newDrugEpsiode!)
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.doseUnit == nil")
                        }
                        else if newDrugEpsiode?.frequency == nil || newDrugEpsiode?.frequency == 0 {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.frequency == nil")
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.regularly == nil {
                            ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all medicines were imported successfully", errorInfo:"some errors in imported event sets: med.regularly == nil")
                            moc.delete(newDrugEpsiode!)
                        }
                        
                    }
                }
                
            } else {
                //ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 18", errorInfo:"can't import DrugsBackup into dictionary array in 'importFramBackup'; filepath is \(sourcePath)")
                ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 18", systemError: nil, errorInfo: "can't import DrugsBackup into dictionary array in 'importFramBackup'; filepath is \(sourcePath)")
                restoreError = true
            }
            
// 3. RecordTypes
            if let dict = dataFilesToDictionaries(filePath: sourcePath!, dictionaryType: recordTypesFileName) {
                let recordTypesDictionaryArray = dict  as [NSDictionary]
                deleteAllRecordTypes()
                
                for recordTypeDictionary in recordTypesDictionaryArray {
                    
                    let newRecordType: RecordType? = {
                        NSEntityDescription.insertNewObject(forEntityName: "RecordType", into: moc) as? RecordType
                    }()
                    
                    if newRecordType != nil {
                        
                        for keyObject in recordTypeDictionary.allKeys {
                            let key = keyObject as! String
                            
                            switch key {
                            case  "name":
                                newRecordType!.name = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["name"] as! Data)) as? String
                            case  "date":
                                newRecordType!.dateCreated = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["date"] as! Data)) as? NSDate
                            case "maxScore":
                                newRecordType!.maxScore = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["maxScore"] as? Data)!) as? NSNumber
                            case "minScore":
                                newRecordType!.minScore = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["minScore"] as? Data)!)  as? NSNumber
                            case "urid":
                                newRecordType!.urid = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["urid"] as! Data)) as? String
                            default:
                                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 19", errorInfo:"backup recordTypes dictionary unrecognised key \(key)")
                            }
                            
                        }
                    }
                    
                    // data QC
                    // ensure essential data is present, otherwise delete/don't import
                    if newRecordType?.name == nil || newRecordType?.name == "" {
                        ErrorManager.sharedInstance().errorMessage(title:"Some import errors occured", message: "Not all graph types were imported successfully", errorInfo:"some errors in imported event sets: recordType.name == nil")
                        moc.delete(newRecordType!)
                    }
                    
                    
                    
                }
            } else {
                // ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 20", errorInfo:"can't import RecordTypesBackup into dictionary array in 'importFramBackup'; filepath is \(sourcePath)")
                ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 20", systemError: nil, errorInfo: "can't import RecordTypesBackup into dictionary array in 'importFramBackup'; filepath is \(sourcePath)")
                restoreError = true
            }
            
            do {
                try  moc.save()
            }
            catch let error as NSError {
                //ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 21", systemError: error, errorInfo:"Error saving moc after loading events from backup in DataIO")
                ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 21", systemError: error, errorInfo: "Error saving moc after loading events from backup in DataIO")
                restoreError = true
            }
        }
        if !restoreError {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "Restore result"), object: nil, userInfo: ["text":"Success. Restore from backup complete"])
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "Restore result"), object: nil, userInfo: ["text":"Backup Failed. Unable to complete restore from Backup"])
            
        }
        
    }
    
    
    static func dataFilesToDictionaries(filePath: String, dictionaryType: String) -> [Dictionary<String,Data>]? {
        // reads file into NSData objects and uses UnArchiver to cast NSData object into Dictionary

        let dictionaryPath = filePath.appending(dictionaryType)

            if FileManager.default.fileExists(atPath: dictionaryPath) {
                let dictionaryURL = NSURL(fileURLWithPath: dictionaryPath)
                
                if let data = NSData.init(contentsOf: dictionaryURL as URL) {
                    
                    if let array = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [Dictionary<String,Data>] {
                        return array
                    } else {
                        //ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 22", errorInfo:"can't convert \(dictionaryType) object into drug array object")
                        ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 22", systemError: nil, errorInfo: "can't convert \(dictionaryType) object into drug array object")
                        return nil
                    }
                } else {
                    //ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 23", errorInfo:"Error loading \(dictionaryType) Data as NSData from file @ \(dictionaryPath)")
                    ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 23", systemError: nil, errorInfo: "Error loading \(dictionaryType) Data as NSData from file @ \(dictionaryPath)")
                    return nil
                }
            }
            else {
                //ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 24", errorInfo: "NSFileManager error in  importFromBackup - can't find \(dictionaryType) file @ \(dictionaryPath)")
                ErrorManager.sharedInstance().addErrorLog(errorLocation: "BackupController Error 24", systemError: nil, errorInfo: "NSFileManager error in  importFromBackup - can't find \(dictionaryType) file @ \(dictionaryPath)")
                return nil
            }
    }
    //MARK: - deleting all current user data
    
    static func deleteAllEvents() {
        
        var events: [Event]!
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            events = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 25", systemError: error, errorInfo: "Error fetching eventList for deletion")
        }
        
        for event in  events {
            moc.delete(event)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 26", systemError: error, errorInfo: "Error deleting eventList")
        }
        
    }
    
    static func deleteAllDrugs() {
        
        var drugs: [DrugEpisode]!
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            drugs = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 27", systemError: error, errorInfo: "Error fetching drugList for deletion")
        }
        
        for drug in  drugs {
            moc.delete(drug)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 28", systemError: error, errorInfo: "Error deleting drugList")
        }
        
    }
    
    static func deleteAllRecordTypes() {
        
        var recordTypes: [RecordType]!
        let fetchRequest = NSFetchRequest<RecordType>(entityName: "RecordType")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            recordTypes = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 29", systemError: error, errorInfo: "Error fetching recordTypes for deletion")
        }
        
        for type in  recordTypes {
            moc.delete(type)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 30", systemError: error, errorInfo: "Error deleting recordTypesList")
        }
        
    }
    
    static func deleteCloudBackups() {
        
        if cloudBackupsFolderURL != nil {
            
            do {
                try FileManager.default.removeItem(at: cloudBackupsFolderURL! as URL)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 31", systemError: error, errorInfo: "DataIO - unable to delete cloud backups")
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue:"CloudBackupFinished"), object: nil)
        }
    }



}
