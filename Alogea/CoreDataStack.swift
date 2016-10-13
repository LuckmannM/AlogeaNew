/*
 * Copyright (c) 2014 Razeware LLC and Modifications to Swift 3 by AppToolFactory 2016
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// Credits also to Bart Jacobs, Code Foundry, for the part of moving an incompatible store to a safe location

// Modified Starter Version 2 by M Luckmann/ AppToolFactory.co.uk - 2016

import Foundation
import CoreData
import CloudKit
import UIKit

class CoreDataStack: CustomStringConvertible {
    var modelName : String
    var storeName : String
    var store : NSPersistentStore?
    
    
    init(modelName: String, storeName: String,
         options: NSDictionary? = nil) {
        self.modelName = modelName
        self.storeName = storeName
    }
    
    var description : String
    {
        return "context: \(context)\n" +
            "modelName: \(modelName)" +
        "storeURL: \(storeURL)\n"
    }
    
    var modelURL : NSURL {
        return Bundle.main.url(forResource: self.modelName, withExtension: "momd") as NSURL? ?? NSURL()
    }
    
    var storeURL : NSURL {
        let storePaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true) as [String]
        let storePath = String(storePaths.first!) as NSString
        let fileManager = FileManager.default
        
        do {
            try fileManager.createDirectory(atPath: storePath as String, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating storePath \(storePath): \(error)")
        }
        let sqliteFilePath = storePath.appendingPathComponent(storeName + ".sqlite")
        
        return NSURL(fileURLWithPath: sqliteFilePath)
    }
    
    lazy var model : NSManagedObjectModel = NSManagedObjectModel(contentsOf: self.modelURL as URL)!
    
    
    
    // the options[] were missing in the CoreData project; the options make the sync succeed
    // the NSPSC generates storage event logs:
    // Using local storage: 1 for new NSFileManager current token if changes to the store are stored locally,
    // e.g. if there is no network access; these changes will not appear in iCloud and and other devices until
    // Using local storage: 0 for new NSFileManager current token apears; this indicates that the iCloud store is available and is synced
    lazy var coordinator : NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        var storeError : NSError?
        let URLPersistentStore = self.applicationStoresDirectory().appendingPathComponent("PainDiaryModel.sqlite")
        
        do {
            self.store = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                            configurationName: nil,
                                            at: self.storeURL as URL,
                                            options: [NSPersistentStoreUbiquitousContentNameKey: "Alogea",
                                                                              NSMigratePersistentStoresAutomaticallyOption: true,
                                                                              NSInferMappingModelAutomaticallyOption: true])
        } catch  {
            // if there is an error with an incompatible store the below moves the incompatibel store
            // to a separate directory and creates a new store
            var userInfo = [String: AnyObject]()
            userInfo[NSLocalizedDescriptionKey] = "There was an error creating or loading the applications saved date" as AnyObject?
            userInfo[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the applications saved state" as AnyObject?
            userInfo[NSUnderlyingErrorKey] = storeError!
            let wrappedError = NSError(domain: "co.uk.PainApp", code: 1001, userInfo: userInfo)
            
            print("\(storeError) \(storeError!.userInfo)")
            
            let userDefaults = UserDefaults.standard
            userDefaults.set(true, forKey: "didDetectIncompatibleStore")
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: URLPersistentStore!.path) {
                let nameIncompatibleStore  = self.nameForIncompatibleStore()
                let URLCorruptPersistentStore  = self.applicationStoresDirectory().appendingPathComponent(nameIncompatibleStore)
                
                do {
                    try fileManager.moveItem(at: URLPersistentStore!, to: URLCorruptPersistentStore!)
                } catch  {
                    print("\(error) in NSPersistentStoreCoordinator fileManager function")
                }
            }
            
            do {
                let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: URLPersistentStore, options: options)
            } catch  {
                print("\(error) in in NSPersistentStoreCoordinator storeMigration function")
            }
        }
        
        return coordinator
    }()
    
    
    
    lazy var context : NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.coordinator
        
        return context
    }()
    
    var updateContextWithUbiquitousChangesObserver: Bool = false {
        willSet {
            ubiquitousChangesObserver = newValue ? NotificationCenter.default : nil
        }
    }
    
    private var ubiquitousChangesObserver : NotificationCenter? {
        
        didSet {
            oldValue?.removeObserver(self,name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: coordinator)
            
            ubiquitousChangesObserver?.addObserver(self, selector: #selector(persistentStoreDidImportUbiquitousContentChanges(notification:)), name: .NSPersistentStoreDidImportUbiquitousContentChanges, object: coordinator)
            
            oldValue?.removeObserver(self, name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: coordinator)
            ubiquitousChangesObserver?.addObserver(self, selector: #selector(persistentStoreCoordinatorWillChangeStores(notification:)), name: Notification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: coordinator)
        }
        
    }
    
    @objc func persistentStoreDidImportUbiquitousContentChanges (notification: NSNotification) {
        context.perform {
            self.context.mergeChanges(fromContextDidSave: notification as Notification)
        }
    }
    
    @objc func persistentStoreCoordinatorWillChangeStores (notification: NSNotification) {
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                print("Error saving \(error)", terminator: "")
            }
        }
        context.reset()
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                print("Error saving \(error)")
            }
        }
    }
    
    private func applicationStoresDirectory() -> NSURL {
        
        let fileManager = FileManager.default
        let URLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let applicationSupportDirectory = URLs[URLs.count - 1]
        let URL = applicationSupportDirectory.appendingPathComponent("Stores")
        
        if !fileManager.fileExists(atPath: URL.path) {
            do {
                try fileManager.createDirectory(at: URL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                let createError = error as NSError
                print("\(createError), \(createError.userInfo)")
            }
        }
        
        return URL as NSURL
    }
    
    
    private func applicationIncompatibleStoresDirectory() -> NSURL {
        
        let fileManager = FileManager.default
        let URLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let applicationSupportDirectory = URLs[URLs.count - 1]
        let URL = applicationSupportDirectory.appendingPathComponent("Incompatible")
        
        if !fileManager.fileExists(atPath: URL.path) {
            do {
                try fileManager.createDirectory(at: URL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                let createError = error as NSError
                print("\(createError), \(createError.userInfo)")
            }
        }
        
        return URL as NSURL
    }
    
    private func nameForIncompatibleStore() -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        return "\(dateFormatter.string(from: NSDate() as Date)).sqlite"
        
    }
    
    
}