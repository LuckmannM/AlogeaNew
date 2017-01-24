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
            print("Error fetching recordTyped in DataIO : \(error)")
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
            print("Error fetching events in DataIO : \(error)")
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
            print("Error fetching DrugEpisodes in DataIO : \(error)")
        }
        return array
    }
    
    static var localBackupDirectoryPath: String? {
        
        let documentDirectoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if documentDirectoryPaths.count > 0 {
            let directoryName = backupDirectoryName
            let backupDirectoryPath = documentDirectoryPaths[0].appending(directoryName)
            if FileManager.default.fileExists(atPath: backupDirectoryPath) {
                return backupDirectoryPath
            } else {
                return nil
            }
        } else {
            print("error: did not establish backup path to documentDirectory")
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
                    print("Error creating BackupDirectory in DataIO: \(error)")
                }
            }
            return tempDirectoryPath
            
        } else {
            return nil
        }
    }
    
    static var cloudBackupsFolderURL: NSURL? {
        
        if FileManager.default.ubiquityIdentityToken == nil {
            print("iCloud drive access not available")
            return nil
        }
        
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            let cloudDocumentBackupsURL = iCloudURL.appendingPathComponent("Backups")
            if !FileManager.default.fileExists(atPath: cloudDocumentBackupsURL.path) {
                do {
                    try FileManager.default.createDirectory(atPath:cloudDocumentBackupsURL.path, withIntermediateDirectories: true, attributes: nil)
                    print("Had to create Cloud/Documents/Backups folder, \(cloudDocumentBackupsURL)")
                } catch let error as NSError {
                    print("can't create /Cloud/Documents/Backups directory: \(error)")
                }
                
            }
            return cloudDocumentBackupsURL as NSURL?
        } else {
            print("can't find URL of iCloud Container folder")
            return nil
        }
    }
    
    // MARK: custom functions
    
    class func copyBackupsToCloud(directoryToCopyPath: String) {
        
        var tempBackupURL: NSURL
        var tempLocalDirectoryPath: String
        let backupFolderName = "/" + (directoryToCopyPath as NSString).lastPathComponent
        
        
        
        if FileManager.default.ubiquityIdentityToken == nil {
            print("iCloud drive access not available")
            return
        }
        
        print("trying to move the directory \(directoryToCopyPath) to iCloud...")
        
        
        let backupDirectoryURL = NSURL(fileURLWithPath: directoryToCopyPath)
        
        // first copy the files to a temp directory, for later moving to CloudDirectory
        if tempBackupDirectoryPath != nil {
            
            // remove any remaining local /Tmp directory files from previous operations and re-create local /Tmp folder
            do {
                try FileManager.default.removeItem(atPath: tempBackupDirectoryPath!)
            } catch let error as NSError {
                print("can't remove /Temp directory: \(error)")
            }
            do {
                try FileManager.default.createDirectory(atPath: tempBackupDirectoryPath!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("can't re-create /Temp directory: \(error)")
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
                print("can't duplicate backupFolder from /Backups or /Temp directory: \(error)")
            }
            
        } else {
            print("can't find temp directory for backup")
            return
        }
        
        if let  iCloudURL = cloudBackupsFolderURL {
            
            let newCloudBackupFolder = (iCloudURL.path)?.appending(backupFolderName)
            if FileManager.default.fileExists(atPath: newCloudBackupFolder!) {
                // delete existing backup to create new
                print("Deleting existing Cloud \(newCloudBackupFolder) folder to overwrite with new one")
                do {
                    try FileManager.default.removeItem(atPath: newCloudBackupFolder!)
                } catch let error as NSError {
                    print("Error deleting existing Cloud 'Backups' folder in DataIO: \(error)")
                }
            }

            do {
                try  FileManager.default.setUbiquitous(true, itemAt: tempBackupURL as URL, destinationURL: NSURL(fileURLWithPath:  newCloudBackupFolder!) as URL)
                print("moved the backups directory to iCloud!")
                
            } catch let error as NSError {
                print("error writing Backups directory to iCloud documents @ \(newCloudBackupFolder!): \(error)")
            }
        } else {
            print("error in DataIO moveBackupsToICloud  - can't get iCloudURL for default directory. Try to create ")
            if let cloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/Backups") {
                do {
                    try FileManager.default.createDirectory(at: cloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("Error creating  Cloud Backups Directory in DataIO: \(error)")
                }
            }
            print("error in DataIO moveBackupsToICloud  - can't get default iCloudURL")
            
        }
    }
    
    class func BackupAllUserData() {
        
        let eventsDictionary = createEventsDictionary() as NSArray
        let drugsDictionary = createDrugsDictionary() as NSArray
        let recordTypesDictionary = createRecordTypesDictionary() as NSArray
        
        if let backupDirectoryPath = checkCreateBackupDirectory() {
            
            var fileURL = NSURL(fileURLWithPath: (backupDirectoryPath.appending(eventFileName)))
            if !eventsDictionary.write(to: fileURL as URL, atomically: true) {
                print("error writing the eventsDictionary to file \(fileURL)")
                print("events dictionary is \(eventsDictionary)")
            } else {
                print("saved eventsDict @ \(fileURL)")
            }
            
            fileURL = NSURL(fileURLWithPath: (backupDirectoryPath.appending(drugsFileName)))
            if !drugsDictionary.write(to: fileURL as URL, atomically: true) {
                print("error writing the drugsDictionary to file \(fileURL)")
            }
            
            fileURL = NSURL(fileURLWithPath: (backupDirectoryPath.appending(recordTypesFileName)))
            if !recordTypesDictionary.write(to: fileURL as URL, atomically: true) {
                print("error writing the recordTypesDictionary to file \(fileURL)")
            }
            
            if UserDefaults.standard.bool(forKey: iCloudBackUpsOn) {
                copyBackupsToCloud(directoryToCopyPath: backupDirectoryPath)
            }
            
        } else {
            print("error - no backup directory - dictionaries not saved to file")
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
                                print("backup event dictionary unrecognised key \(key)")
                            }
                            
                            print("imported new event: \(newEvent!)")
                        }
                        
                        // data QC
                        // ensure essential data is present, otherwise delete/don't import
                        if newEvent?.name == nil || newEvent?.name == "" {
                            print("deleted event import object due to lack of .name \(newEvent)")
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
                print("restored \(eventsDictionaryArray.count) events from backup \(folderName))")
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
                            }
                            
                        }
                        
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
                
                print("restored \(drugsDictionaryArray.count) drugs from backup \(folderName))")
                
                
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
                                print("backup recordTypes dictionary unrecognised key \(key)")
                            }
                            
                        }
                    }
                    
                    // data QC
                    // ensure essential data is present, otherwise delete/don't import
                    if newRecordType?.name == nil || newRecordType?.name == "" {
                        print("deleted recordType import object due to lack of .name \(newRecordType)")
                        moc.delete(newRecordType!)
                    }
                    
                    
                    
                }
                print("restored \(recordTypesDictionaryArray.count) recordTypes from backup \(folderName))")
                
            }
            
            do {
                try  moc.save()
            }
            catch let error as NSError {
                print("Error saving moc after loading events from backup in DataIO: \(error)", terminator: "")
            }
            
            // this restores AppSettings.RecordTypes[0] as stored graphType
            // if none is existing / imported, AppSettings.RecordType creates a default
            //            AppSettings.sharedInstance().storeDefaultGraphType(nil)
            
        }
        
    }
    
    // MARK: - import backup dictionaries
    
    static func importEventsDictionaries(filePath: String) -> [Dictionary<String,Data>]? {
        
        let eventDictionaryPath = filePath.appending(eventFileName)
        if FileManager.default.fileExists(atPath: eventDictionaryPath) {
            let eventDictionaryURL = NSURL(fileURLWithPath: eventDictionaryPath)
            
            print("trying to load file contents \(eventDictionaryPath) into dictionary")
            if let eventsDictionaryArray = NSArray.init(contentsOf: eventDictionaryURL as URL) {
                return eventsDictionaryArray as? [Dictionary]
            }
            else {
                print("NSDictionary contentsWithURL Error loading Backup eventDictionary in DataIO @ \(eventDictionaryPath)")
                return nil
            }
            
        }
        else {
            print("NSFileManager error in DataIO  importFromBackup - can't find eventDictionary @ \(eventDictionaryPath)")
            
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
            
            print("trying to load file contents \(drugDictionaryPath) into dictionary")
            if let drugsDictionaryArray = NSArray.init(contentsOf: drugsDictionaryURL as URL) {
                return drugsDictionaryArray as? [Dictionary]
            }
            else {
                print("NSDictionary contentsWithURL Error loading Backup drugsDictionary in DataIO @ \(drugDictionaryPath)")
                return nil
            }
            
        }
        else {
            print("NSFileManager error in DataIO  importFromBackup - can't find drugDictionary @ \(drugDictionaryPath)")
            return nil
        }
    }
    
    static func importRecordTypesDictionaries(filePath: String) -> [Dictionary<String,Data>]? {
        
        let recordTypesDictionaryPath = filePath.appending(recordTypesFileName)
        if FileManager.default.fileExists(atPath: recordTypesDictionaryPath) {
            let recordTypesDictionaryURL = NSURL(fileURLWithPath: recordTypesDictionaryPath)
            
            print("trying to load file contents \(recordTypesDictionaryPath) into dictionary")
            if let recordTypesDictionaryArray = NSArray.init(contentsOf: recordTypesDictionaryURL as URL) {
                return recordTypesDictionaryArray as? [Dictionary]
            }
            else {
                print("NSDictionary contentsWithURL Error loading Backup recordType Dictionary in DataIO @ \(recordTypesDictionaryPath)")
                return nil
            }
            
        }
        else {
            print("NSFileManager error in DataIO  importFromBackup - can't find record Type Dictionary @ \(recordTypesDictionaryPath)")
            return nil
        }
    }
    
    // MARK: - filePaths
    
    static func checkCreateBackupDirectory() -> String? {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateFormat = "d.M.YY"
            return formatter
        }()
        
        
        let documentDirectoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if documentDirectoryPaths.count > 0 {
            let directoryName = backupDirectoryName
            let backupDirectoryPath = documentDirectoryPaths[0].appending(directoryName)
            if !FileManager.default.fileExists(atPath: backupDirectoryPath) {
                do {
                    try FileManager.default.createDirectory(atPath: backupDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    print("Error creating BackupDirectory in DataIO: \(error)")
                }
            }
            
            let backupFolderPath = backupDirectoryPath.appending("/Backup " + dateFormatter.string(from: Date()))
            if !FileManager.default.fileExists(atPath: backupFolderPath) {
                
                do {
                    try FileManager.default.createDirectory(atPath: backupFolderPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    print("Error creating BackupDirectory in DataIO: \(error)")
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
    
    
    static func createEventsDictionary() -> [NSDictionary] {
        
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
        print("backup eventsDictionary created with \(events.count) events")
        return eventsDictionaryArray
        
    }
    
    static func createDrugsDictionary() -> [NSDictionary] {
        
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
        print("backup drugsDictionary created with \(drugs.count) drugs")
        return drugsDictionaryArray
    }
    
    static func createRecordTypesDictionary() -> [NSDictionary] {
        
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
            
            print("export recordType \(type.name) to backupDictionary")
        }
        print("backup recordTypesDictionary created with \(recordTypes.count) recordTypes")
        return recordTypesDictionaryArray
    }
    
    
    // MARK: - delete records
    
    
    static func deleteAllEvents() {
        
        var events: [Event]!
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            events = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        
        for event in  events {
            moc.delete(event)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            print("Error saving moc after deleting events in DataIO: \(error)", terminator: "")
        }
        
    }
    
    static func deleteAllDrugs() {
        
        var drugs: [DrugEpisode]!
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            drugs = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        
        for drug in  drugs {
            moc.delete(drug)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            print("Error saving moc after deleting drugs in DataIO: \(error)", terminator: "")
        }
        
    }
    
    static func deleteAllRecordTypes() {
        
        var recordTypes: [RecordType]!
        let fetchRequest = NSFetchRequest<RecordType>(entityName: "RecordType")
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            recordTypes = try moc.fetch(fetchRequest)
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        
        for type in  recordTypes {
            print("deleting recordType \(type.name) ... ")
            moc.delete(type)
        }
        do {
            try  moc.save()
        }
        catch let error as NSError {
            print("Error saving moc after deleting recordTypes in DataIO: \(error)", terminator: "")
        }
        
    }
    
    static func deleteCloudBackups() {
        
        if cloudBackupsFolderURL != nil {
            
            do {
                try FileManager.default.removeItem(at: cloudBackupsFolderURL! as URL)
            } catch let error as NSError {
                print("DataIO - unable to delete cloud backups, error:  \(error)")
            }
            
        }
    }
}
