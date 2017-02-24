//
//  BackupController.swift
//  Alogea
//
//  Created by mikeMBP on 23/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

//
//  DataExportAndImport.swift
//  PainDiaryModelFramework
//
//  Created by mikeMBP on 28/05/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class BackupController {
    
    static let eventFileName = "/EventsDictionary"
    static let drugsFileName = "/DrugsDictionary"
    static let recordTypesFileName = "/RecordTypesDictionary"
    static let backupDirectoryName = "/Backups"
    static let tempDirectoryName = "/Tmp"
    
    static let iCloudSubDirectoryName = "Alogea Backups"
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
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
    
    static var localBackupDirectoryPath: String? {
        
        let documentDirectoryPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        if documentDirectoryPaths.count > 0 {
            let directoryName = backupDirectoryName
            let backupDirectoryPath = documentDirectoryPaths[0].appending(directoryName)
            if FileManager.default.fileExists(atPath: backupDirectoryPath) {
                return backupDirectoryPath
            } else {
                return nil
            }
        } else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 4", errorInfo:"did not establish backup path to documentDirectory")
            return nil
        }
    }
    
    static var tempBackupDirectoryPath: String? {
        
        var documentDirectoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if documentDirectoryPaths.count > 0 {
            let directoryName = tempDirectoryName
            let tempDirectoryPath = documentDirectoryPaths[0].appending(directoryName)
            
            if !FileManager.default.fileExists(atPath: tempDirectoryPath) {
                do {
                    try FileManager.default.createDirectory(atPath: tempDirectoryPath, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 5", systemError: error, errorInfo:"Error creating BackupDirectory")
                }
            }
            return tempDirectoryPath
            
        } else {
            return nil
        }
    }
    
    static var cloudBackupsFolderURL: NSURL? {
        
        if FileManager.default.ubiquityIdentityToken == nil {
            ErrorManager.sharedInstance().errorMessage(title: "iCloud storage currently not accessible", message: "Your backup has not been saved to iCloud")
            return nil
        }
        
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudSubDirectoryName) {
            let cloudDocumentBackupsURL = iCloudURL.appendingPathComponent("\(UIDevice.current.name) Backups")
            if !FileManager.default.fileExists(atPath: cloudDocumentBackupsURL.path) {
                do {
                    try FileManager.default.createDirectory(atPath:cloudDocumentBackupsURL.path, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 6", systemError: error, errorInfo:"can't create iCloud Backups directory")
                }
                
            }
            return cloudDocumentBackupsURL as NSURL?
        } else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 7", errorInfo:"can't find URL of iCloud Container folder")
            return nil
        }
    }
    
    // MARK: custom functions
    
    class func copyBackupsToCloud(directoryToCopyPath: String) {
        
//        var tempBackupURL: NSURL
//        var tempLocalDirectoryPath: String
        let cloudBackupFolderName = "/" + (directoryToCopyPath as NSString).lastPathComponent
        
        
        
        if FileManager.default.ubiquityIdentityToken == nil {
            ErrorManager.sharedInstance().errorMessage(title: "iCloud currently not accessible", message: "iCloud backup can't be saved")
            return
        }
        
        let backupDirectoryURL = NSURL(fileURLWithPath: directoryToCopyPath)
        
        // first copy the files to a temp directory, for later moving to CloudDirectory
        // if tempBackupDirectoryPath != nil {
            
            // remove any remaining local /Tmp directory files from previous operations and re-create local /Tmp folder
            /*
            do {
                try FileManager.default.removeItem(atPath: tempBackupDirectoryPath!)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 8", systemError: error)
            }
            do {
                try FileManager.default.createDirectory(atPath: tempBackupDirectoryPath!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 9", systemError: error)
            }
            
            
            // DEBUG
            /*
             do {
             try FileManager.default.removeItemAtPath(cloudBackupsFolderURL!.path!)
             } catch let error as NSError {
             print("can't remove /iCloud/Backups directory: \(error)")
             }
             do {
             try FileManager.default.createDirectoryAtPath(cloudBackupsFolderURL!.path!, withIntermediateDirectories: true, attributes: nil)
             } catch let error as NSError {
             print("can't re-create /iCloud/Backups directory: \(error)")
             }
             */
            // DEBUG
            
            tempLocalDirectoryPath = tempBackupDirectoryPath!.appending(backupFolderName)
            tempBackupURL = NSURL(fileURLWithPath:  tempLocalDirectoryPath)
            
            do {
                try FileManager.default.copyItem(at: (backupDirectoryURL as URL), to: NSURL(fileURLWithPath: tempLocalDirectoryPath) as URL)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 10", systemError: error, errorInfo:"can't duplicate backupFolder from /Backups or /Temp directory")
            }
            
        } else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 11", errorInfo:"can't find temp directory for backup")
            return
        }
             */
        
        if let  iCloudURL = cloudBackupsFolderURL {
            
            let newCloudBackupFolder = (iCloudURL.path)?.appending(cloudBackupFolderName)
            
            if FileManager.default.fileExists(atPath: newCloudBackupFolder!) {
                // delete any existing/previous backup folder with same name/date to create new
                do {
                    try FileManager.default.removeItem(atPath: newCloudBackupFolder!)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 12", systemError: error, errorInfo:"Error deleting existing Cloud 'Backups' folder")
                }
            }

            do {
                // this does the actual copying to iCloud
                try  FileManager.default.setUbiquitous(true, itemAt: backupDirectoryURL as URL, destinationURL: NSURL(fileURLWithPath:  newCloudBackupFolder!) as URL)
                
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 13", systemError: error, errorInfo:"error writing Backups directory to iCloud documents")
            }
            
        }
        else {
            if let cloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/Backups") {
                do {
                    try FileManager.default.createDirectory(at: cloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 13", systemError: error, errorInfo:"Error creating  Cloud Backups Directory")
                }
            }
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 14", errorInfo:"error in DataIO moveBackupsToICloud  - can't get default iCloudURL")
        }
    }
    
    class func BackupAllUserData() {
        
        let eventsData = createEventsDictionary()
        let drugsData = createDrugsDictionary()
        let recordTypesData = createRecordTypesDictionary()
        
        guard let backupDirectoryPath = checkCreateLocalBackupDirectory()  else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 15; can't save Backup", errorInfo:"error - no backup directory")
            return
        }
        
        fileIO(backupDirectoryPath: backupDirectoryPath, fileName: eventFileName, data: eventsData, cloud: false)
        fileIO(backupDirectoryPath: backupDirectoryPath, fileName: drugsFileName, data: drugsData, cloud: false)
        fileIO(backupDirectoryPath: backupDirectoryPath, fileName: recordTypesFileName, data: recordTypesData, cloud: false)
        
        
        if UserDefaults.standard.bool(forKey: iCloudBackUpsOn) {
            guard let backupDirectoryPath = checkCreateCloudBackupDirectory()  else {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 15; can't save CloudBackup", errorInfo:"error - no cloud backup directory")
                return
            }

            fileIO(backupDirectoryPath: backupDirectoryPath, fileName: eventFileName, data: eventsData, cloud: true)
            fileIO(backupDirectoryPath: backupDirectoryPath, fileName: drugsFileName, data: drugsData, cloud: true)
            fileIO(backupDirectoryPath: backupDirectoryPath, fileName: recordTypesFileName, data: recordTypesData, cloud: true)

            copyBackupsToCloud(directoryToCopyPath: backupDirectoryPath)
        }
    }
    
    static func fileIO(backupDirectoryPath: String, fileName: String, data: Data, cloud: Bool) {
        
        let fileURL = NSURL(fileURLWithPath: (backupDirectoryPath.appending(fileName)))
        var tempURL: NSURL?
            
        // check if a similar file exists already
        if FileManager.default.fileExists(atPath: eventFileName) {
            // if it does rename to temp and delete after successful write or rename is write fails
            tempURL = NSURL(fileURLWithPath: (backupDirectoryPath.appending(fileName + "Temp")))
            do {
                try FileManager.default.copyItem(at: fileURL as URL, to: tempURL as! URL)
                try FileManager.default.removeItem(at: fileURL as URL)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 15.1", systemError: error, errorInfo:"error copying or removing existing backupfile \(fileURL) to \(tempURL)")
            }
        }
        
        // write data to file
        do {
            if cloud {
                try data.write(to: fileURL as URL, options: [.atomic]) // file not encrypted for iCloud
            } else {
                try data.write(to: fileURL as URL, options: [.completeFileProtectionUnlessOpen, .atomic]) // file encrypted for local
            }
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 16", systemError: error, errorInfo:"error trying to encrypt file \(fileURL)")
        }
        
        // delete old temp file
        if FileManager.default.fileExists(atPath: (fileName + "Temp")) {
            // if it does rename to temp and delete after successful write or rename is write fails
            do {
                try FileManager.default.removeItem(at: tempURL as! URL)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 15.2", systemError: error, errorInfo:"error removing temp backupfile \(fileURL) to \(tempURL)")
            }
        }
    }
    
    static func importFromBackup(folderName: String, fromLocalBackup: Bool) {
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        var sourceBackupPath: String?
        
        if fromLocalBackup {
            sourceBackupPath = localBackupDirectoryPath?.appending(folderName)
        } else {
            sourceBackupPath = (cloudBackupsFolderURL?.appendingPathComponent(folderName, isDirectory: true))?.path
        }
        
        if sourceBackupPath != nil {
            
            // 1. Events
            if let dict = importEventsDictionaries(filePath: sourceBackupPath!) {
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
                                newEvent!.vas = (NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["vas"] as! Data)) as? Double)!
                            case "duration":
                                newEvent!.duration = (NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["duration"] as! Data)) as? Double)!
                            case "location":
                                newEvent!.bodyLocation = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["location"] as! Data)) as? String
                            case "note":
                                newEvent!.note = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["note"] as! Data)) as? String
                            case "outcome":
                                newEvent!.outcome = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["outcome"] as! Data)) as? String
                            case "locationImage":
                                newEvent!.locationImage = NSKeyedUnarchiver.unarchiveObject(with: (eventDictionary["locationImage"]as! Data)) as? NSObject
                            default:
                                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 19", errorInfo:"backup event dictionary unrecognised key \(key)")
                            }
                            
                        }
                        
                        // data QC
                        // ensure essential data is present, otherwise delete/don't import
                        if newEvent?.name == nil || newEvent?.name == "" {
                            print("deleted event import object due to lack of .name \(newEvent)")
// error log without display
                            moc.delete(newEvent!)
                        } else if newEvent?.type == nil || newEvent?.type == "" {
                            print("deleted event import object due to lack of .type \(newEvent)")
                            moc.delete(newEvent!)
                        } else if newEvent?.date == nil {
                            print("deleted event import object due to lack of .date \(newEvent)")
                            moc.delete(newEvent!)
                        }
                    }
                }
            } else {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 38", errorInfo:"can't import EventsBackup into dictionary array in 'importFramBackup'; filepath is \(sourceBackupPath)")
            }
            
            // 2. Drugs
            if let dict = importDrugsDictionaries(filePath: sourceBackupPath!) {
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
                            default:
                                print("backup drug dictionary unrecognised key \(key)")
                                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 20")
                            }
                            
                        }
                        
                        newDrugEpsiode?.awakeFromFetch()
                        
                        // data QC
                        // ensure essential data is present, otherwise delete/don't import
                        if newDrugEpsiode?.name == nil || newDrugEpsiode?.name == "" {
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.drugID == nil || newDrugEpsiode?.drugID == "" {
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.startDate == nil {
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.doses == nil {
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.doseUnit == nil {
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.frequency == nil || newDrugEpsiode?.frequency == 0 {
                            moc.delete(newDrugEpsiode!)
                        }
                        else if newDrugEpsiode?.regularly == nil {
                            moc.delete(newDrugEpsiode!)
                        }
                        
                    }
                }
                
            } else {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 37", errorInfo:"can't import DrugsBackup into dictionary array in 'importFramBackup'; filepath is \(sourceBackupPath)")
            }
            
            // 3. RecordTypes
            if let dict = importRecordTypesDictionaries(filePath: sourceBackupPath!) {
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
                                newRecordType!.maxScore = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["maxScore"] as! Data)) as! Double
                            case "minScore":
                                newRecordType!.minScore = NSKeyedUnarchiver.unarchiveObject(with: (recordTypeDictionary["minScore"] as! Data)) as! Double
                            default:
                                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 21", errorInfo:"backup recordTypes dictionary unrecognised key \(key)")
                            }
                            
                        }
                    }
                    
                    // data QC
                    // ensure essential data is present, otherwise delete/don't import
                    if newRecordType?.name == nil || newRecordType?.name == "" {
                        moc.delete(newRecordType!)
                    }
                    
                    
                    
                }
            } else {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 39", errorInfo:"can't import RecordTypesBackup into dictionary array in 'importFramBackup'; filepath is \(sourceBackupPath)")
            }
            
            do {
                try  moc.save()
            }
            catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 22", systemError: error, errorInfo:"Error saving moc after loading events from backup in DataIO")
            }
            
            
        }
        
    }
    
    // MARK: - import backup dictionaries
    
    static func importEventsDictionaries(filePath: String) -> [Dictionary<String,Data>]? {
        
        let eventDictionaryPath = filePath.appending(eventFileName)
        if FileManager.default.fileExists(atPath: eventDictionaryPath) {
            let eventDictionaryURL = NSURL(fileURLWithPath: eventDictionaryPath)
            
            // OLD
//            if let eventsDictionaryArray = NSArray.init(contentsOf: eventDictionaryURL as URL) {
//                return eventsDictionaryArray as? [Dictionary]
//            }
//            else {
//                print("NSDictionary contentsWithURL Error loading Backup eventDictionary in DataIO @ \(eventDictionaryPath)")
//                return nil
//            }
            
            //NEW
            if let eventsData = NSData.init(contentsOf: eventDictionaryURL as URL) {
                if let array = NSKeyedUnarchiver.unarchiveObject(with: eventsData as Data) as? [Dictionary<String,Data>] {
                    return array
                } else {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 41", errorInfo:"can't convert eventsData object into drug array object")
                    return nil
                }
            } else {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 23", errorInfo:"Error loading eventsDat as NSData from file @ \(eventDictionaryPath) could not be read")
                return nil
            }
            
        }
        else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 23", errorInfo:"Error loading eventsData as NSData from file @ \(eventDictionaryPath) could not be read")
            do {
                let filesInBckupFolder = try FileManager.default.contentsOfDirectory(atPath: filePath)
                print("files contained in \(filePath) are ...")
                for file in filesInBckupFolder {
                    print("...\(file)")
                    let readable = FileManager.default.isReadableFile(atPath: eventDictionaryPath)
                    print("...file readable? \(readable)")
                }
            }
            catch let error as NSError {
                print("Filemanager reported error when getting contents of folder \(filePath): error is \(error)")
            }
            
            // DEBUG
            //                let eventDictionaryURL = NSURL(fileURLWithPath: eventDictionaryPath)
            //
            //                print("trying to nonetheless load file contents \(eventDictionaryPath) into dictionary")
            //                if let eventsDictionaryArray = NSArray.init(contentsOfURL: eventDictionaryURL) {
            //                    return eventsDictionaryArray as? [NSDictionary]
            //                }
            //                else {
            //                    print("NSDictionary contentsWithURL Error loading Backup eventDictionary in DataIO @ \(eventDictionaryPath)")
            //                    return nil
            //                }
            // DEBUG
            
            return nil
        }
    }
    
    static func importDrugsDictionaries(filePath: String) -> [Dictionary<String,Data>]? {
        
        let drugDictionaryPath = filePath.appending(drugsFileName)
        if FileManager.default.fileExists(atPath: drugDictionaryPath) {
            let drugsDictionaryURL = NSURL(fileURLWithPath: drugDictionaryPath)
            
            //NEW
            if let drugsData = NSData.init(contentsOf: drugsDictionaryURL as URL) {
                
                if let array = NSKeyedUnarchiver.unarchiveObject(with: drugsData as Data) as? [Dictionary<String,Data>] {
                    return array
                } else {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 40", errorInfo:"can't convert drugsData object into drug array object")
                    return nil
                }
            } else {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 24", errorInfo:"Error loading drugsData as NSData from file @ \(drugDictionaryPath) could not be read")
                return nil
            }
            // OLD
//            if let drugsDictionaryArray = NSArray.init(contentsOf: drugsDictionaryURL as URL) {
//                return drugsDictionaryArray as? [Dictionary]
//            }
//            else {
//                print("Error loading drugsDictionary Backup @ \(drugDictionaryPath)")
//                return nil
//            }
            
        }
        else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 25", errorInfo: "NSFileManager error in DataIO  importFromBackup - can't find drugDictionary @ \(drugDictionaryPath)")
            return nil
        }
    }
    
    static func importRecordTypesDictionaries(filePath: String) -> [Dictionary<String,Data>]? {
        
        let recordTypesDictionaryPath = filePath.appending(recordTypesFileName)
        if FileManager.default.fileExists(atPath: recordTypesDictionaryPath) {
            let recordTypesDictionaryURL = NSURL(fileURLWithPath: recordTypesDictionaryPath)
            
            //NEW
            if let recordTypeData = NSData.init(contentsOf: recordTypesDictionaryURL as URL) {
                if let array = NSKeyedUnarchiver.unarchiveObject(with: recordTypeData as Data) as? [Dictionary<String,Data>] {
                    return array
                } else {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 42", errorInfo:"can't convert recordTypeData object into drug array object")
                    return nil
                }
            } else {
                print("Error loading recordTypesData as NSData from file @ \(recordTypesDictionaryPath) could not be read")
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 26", errorInfo: "can't load NSData from file at path \(recordTypesDictionaryPath)")
                return nil
            }

            //OLD
//            if let recordTypesDictionaryArray = NSArray.init(contentsOf: recordTypesDictionaryURL as URL) {
//                return recordTypesDictionaryArray as? [Dictionary]
//            }
//            else {
//                print("Error loading  recordType Dictionary Backup @ \(recordTypesDictionaryPath)")
//                return nil
//            }
            
        }
        else {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 27", errorInfo: "can't find record Type Dictionary @ \(recordTypesDictionaryPath)")
            return nil
        }
    }
    
    // MARK: - filePaths
    
    static func checkCreateLocalBackupDirectory() -> String? {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "d.M.YY"
            return formatter
        }()
        
        
        let documentDirectoryPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        if documentDirectoryPaths.count > 0 {
            let directoryName = backupDirectoryName
            let backupDirectoryPath = documentDirectoryPaths[0].appending(directoryName)
            if !FileManager.default.fileExists(atPath: backupDirectoryPath) {
                do {
                    try FileManager.default.createDirectory(atPath: backupDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 28", systemError: error, errorInfo: "Error creating BackupDirectory in DataIO")
                }
            }
            
            let backupFolderPath = backupDirectoryPath.appending("/Backup " + dateFormatter.string(from: Date()))
            if !FileManager.default.fileExists(atPath: backupFolderPath) {
                
                do {
                    try FileManager.default.createDirectory(atPath: backupFolderPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 29", systemError: error, errorInfo: "Error creating BackupDirectory in DataIO")
                }
            }
            
            return backupFolderPath
            
        } else {
            return nil
        }
    }
    
    static func checkCreateCloudBackupDirectory() -> String? {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "d.M.YY"
            return formatter
        }()
        
        
        let appSupportDirectoryPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        if appSupportDirectoryPaths.count > 0 {
            let directoryName = backupDirectoryName
            let backupDirectoryPath = appSupportDirectoryPaths[0].appending(directoryName)
            if !FileManager.default.fileExists(atPath: backupDirectoryPath) {
                do {
                    try FileManager.default.createDirectory(atPath: backupDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 28.1", systemError: error, errorInfo: "Error creating CloudBackupDirectory in DataIO")
                }
            }
            
            let backupFolderPath = backupDirectoryPath.appending("/CloudBackup " + dateFormatter.string(from: Date()))
            if !FileManager.default.fileExists(atPath: backupFolderPath) {
                
                do {
                    try FileManager.default.createDirectory(atPath: backupFolderPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 29.1", systemError: error, errorInfo: "Error creating CloudBackupDirectory in DataIO")
                }
            }
            
            return backupFolderPath
            
        } else {
            return nil
        }
    }

    
    static func documentDirectoryPath() -> String? {
        
        let documentDirectoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if documentDirectoryPaths.count > 0 {
            return documentDirectoryPaths[0]
        } else {
            return nil
        }
        
    }
    
    
    // MARK: - create backup dictionaries
    
    
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
    
    
    // MARK: - delete records
    
    
    static func deleteAllEvents() {
        
        var events: [Event]!
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            events = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 30", systemError: error, errorInfo: "Error fetching eventList for deletion")
        }
        
        for event in  events {
            moc.delete(event)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 31", systemError: error, errorInfo: "Error deleting eventList")
        }
        
    }
    
    static func deleteAllDrugs() {
        
        var drugs: [DrugEpisode]!
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            drugs = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 32", systemError: error, errorInfo: "Error fetching drugList for deletion")
        }
        
        for drug in  drugs {
            moc.delete(drug)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 33", systemError: error, errorInfo: "Error deleting drugList")
        }
        
    }
    
    static func deleteAllRecordTypes() {
        
        var recordTypes: [RecordType]!
        let fetchRequest = NSFetchRequest<RecordType>(entityName: "RecordType")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            recordTypes = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 34", systemError: error, errorInfo: "Error fetching recordTypes for deletion")
        }
        
        for type in  recordTypes {
            moc.delete(type)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 35", systemError: error, errorInfo: "Error deleting recordTypesList")
        }
        
    }
    
    static func deleteCloudBackups() {
        
        if cloudBackupsFolderURL != nil {
            
            do {
                try FileManager.default.removeItem(at: cloudBackupsFolderURL! as URL)
            } catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "BackupController Error 36", systemError: error, errorInfo: "DataIO - unable to delete cloud backups")
            }
            
        }
    }
}
