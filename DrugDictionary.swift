//
//  DrugDictionary.swift
//  Alogea
//
//  Created by mikeMBP on 13/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

//
//  PublicFormulary.swift
//  PainDiaryModelFramework
//
//  Created by mikeMBP on 11/01/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

protocol PublicDrugDataBaseDelegate {
    func errorUpdating(error: NSError)
    func modelUpdated()
}

class DrugDictionary: PublicDrugDataBaseDelegate {
    
    class func sharedInstance() -> DrugDictionary {
        return drugFormularyGlobal
    }
    
    var iCloudContainer: CKContainer!
    var publicDB : CKDatabase!
    var cloudDrugArray = [CloudDrug]()
    var iCloudStatus: CKAccountStatus!
    
    var delegate: PublicDrugDataBaseDelegate?
    
    var selectedDrugIndex: Int?
    var inAppStore: InAppStore!
    
    var termsDictionary = Dictionary<String, Int>() // this contains specific terms with indexes related to drug in cloudDrugArray, used for the NewDrug name row dropDown menu for selection
    var drugSelectionTerms = [String]() // contains strings only of the above specific terms to be displayed in NewDrug name namePicker
    var indexedNameDictionary = [String:[Int]]() // this contains all brandNames and substanceNames connected to the index in cloudDrugArray for return to NewDrug row name textField; it does contain a specfic name only once and the cloudDrugIndexes of drugs containing this term
    
    init () {
        print("Cloud DrugDictionary init")
        iCloudContainer = CKContainer.default()
        publicDB = iCloudContainer.publicCloudDatabase
        
        iCloudContainer.accountStatus(completionHandler: {
            (accountStatus, error) -> Void in
            if accountStatus == CKAccountStatus.noAccount {
                self.iCloudStatus = CKAccountStatus.noAccount
                print("iCloud access for Cloud Dictionary not available")
            } else {
                self.iCloudStatus = CKAccountStatus.available
            }
        })

        inAppStore = InAppStore.sharedInstance()
        
        self.delegate = self
        // a bit over the top. An alternative is to abollish the protocol and delegate and just decalre and call in the functions modelUpdated() and errorUpdating() when needed.
        
        fetchPublicRecords()
    }
    /*
    func fetchRecordsByName(name: String) {
        let searchForName = NSPredicate(format: "(displayName = %@)", name)
        let databaseQuery = CKQuery(recordType: "CloudMedicinesDictionary", predicate: searchForName)
        
        publicDB.perform(databaseQuery, inZoneWith: nil, completionHandler: { results, error in
            if error != nil {
                DispatchQueue.main.async() {
                    self.delegate?.errorUpdating(error: error as! NSError)
                    print("DrugDictionary - fetchRecordsByName. performQuery, error loading: \(error)")
                    // *** show disabled iCloud connection icon in e.g. NewDrug VC
                }
            } else {
                // *** show enabled oCloud connection icon in e.g. NewDrug VC
                self.cloudDrugArray.removeAll(keepingCapacity: true)
                for record in results! {
                    let medDataSet = CloudDrug(record: record , database:self.publicDB)
                    self.cloudDrugArray.append(medDataSet)
                    //                    print("found \(self.cloudDrugArray.count) sets in public iCloud Med Database")
                }
                DispatchQueue.main.async() {
                    self.delegate?.modelUpdated()
                    print("")
                }
            }
        }
        )
    }
 */
    
    func fetchPublicRecords(named: String? = nil) {
        
        var searchPredicate: NSPredicate!
        
        if named != nil {
            searchPredicate = NSPredicate(format: "(displayName = %@)", named!)
        } else {
            searchPredicate = NSPredicate(value: true)
        }
        
        let databaseQuery = CKQuery(recordType: "CloudMedicinesDictionary", predicate: searchPredicate)
        
        publicDB.perform(databaseQuery, inZoneWith: nil, completionHandler: { results, error in
            if error != nil {
                DispatchQueue.main.async() {
                    self.delegate?.errorUpdating(error: error as! NSError)
                    // *** show disabled iCloud connection icon in e.g. NewDrug VC
                    // or show user Alert of missgin iCloud link
                }
            } else {
                self.cloudDrugArray.removeAll(keepingCapacity: true)
                for record in results! {
                    let medDataSet = CloudDrug(record: record , database:self.publicDB)
                    self.cloudDrugArray.append(medDataSet)
                    // print("found \(self.cloudDrugArray.count) sets in public iCloud Med Database")
                }
                self.modelUpdated()
                DispatchQueue.main.async() {
                    self.delegate?.modelUpdated()
                    print("")
                }
            }
        }
        )
        
    }
    
    func drugFormularyDisplayNamesArray() -> [String] {
        
        var nameArray = [String]()
        
        for drug in cloudDrugArray {
            nameArray.append(drug.displayName.lowercased())
        }
        
        return nameArray

    }
    
    
    func drugFormularyClassesArray() -> [[String]] {
        
        var classesArray = [[String]]()
        
        for drug in cloudDrugArray {
            classesArray.append(drug.classes)
        }
        
        return classesArray
    }
    
    func matchingDrugNames(name: String) -> String? {
        
        
        if inAppStore.checkDrugFormularyAccess() == false {
             return nil
        }
        
        drugSelectionTerms = termsDictionary.keys.filter({$0.lowercased().contains(name.lowercased())})
        
        drugSelectionTerms.sort(by: < ) // these the terms used for the namePickerView in NewDrug name row
        
        let firstMatch = indexedNameDictionary.keys.first(where: { (key) -> Bool in
            key.contains(name)
        })
//        print("firstMatch is \(firstMatch)")
        
        let matchingKVPair = indexedNameDictionary.lazy.filter({$0.0.contains(name)}).first
//        print("firstMatchingPair is \(matchingKVPair)")
        
        
        if firstMatch != nil {
            for index in (matchingKVPair?.value)! {
                if firstMatch!.contains("®") { selectedDrugIndex = index }
                else {
                    if cloudDrugArray[index].substances$ == firstMatch! as String {
                        selectedDrugIndex = index
                        break
                    }
                }
            }
            return firstMatch! as String
        } else {
            selectedDrugIndex = nil
            return nil
        }
    }
    
    
    func returnSelectedPublicDrug(name: String, index: Int = -1) -> CloudDrug? {
        
        guard inAppStore.checkDrugFormularyAccess() == true else { return nil }
        
        guard selectedDrugIndex != nil else { return nil }
        
        return cloudDrugArray[selectedDrugIndex!]
        
    }
    
    func errorUpdating(error: NSError) {

        print("error loading DrugDictionary: \(error)")
        // *** consider displaying an alert prompting user to log into iCloud

    }
    
    func modelUpdated() {
        
        var drugIndex = 0
        
        termsDictionary.removeAll()
        indexedNameDictionary.removeAll()
        
        for drug in cloudDrugArray {
            
            // build termDictionary: for NewDrug.name dropDown menu, all terms containing a string
            for term in drug.dictionaryTerms {
                termsDictionary[term] = drugIndex
            }
            
            // build indexedNameDictionary: for NewDrug.name textField, only one matching term for display
            for brandTerm in drug.brandNames {
                
                var brand = String()
                if brandTerm == "" {
                    brand = drug.displayName
                } else {
                    brand = brandTerm + "®"
                }
                
                if  !indexedNameDictionary.keys.contains(where: { (key) -> Bool in
                    key == brandTerm })
                {
                    indexedNameDictionary[brand] = [drugIndex]
                } else {
                    if !indexedNameDictionary[brandTerm]!.contains(drugIndex)
                    {
                        (indexedNameDictionary[brand])?.append(drugIndex)
                    }
                }

            }
            
            for substance in drug.substances {
                if  !indexedNameDictionary.keys.contains(where: { (key) -> Bool in
                    key == substance })
                {
                    indexedNameDictionary[substance] = [drugIndex]
                } else {
                    if !indexedNameDictionary[substance]!.contains(drugIndex)
                    {
                        (indexedNameDictionary[substance])?.append(drugIndex)
                    }
                }
                
            }
            
            drugIndex += 1
        }
        

        print("cloud drug termsDictionary updated")
        print("termsDictionary:")
        for term in termsDictionary {
            print(term)
        }
        print("")
        print("indexedNameDictionary :")
        for term in indexedNameDictionary {
            print(term)
        }

        
        /*
        var drugIndex = 0
        
        termsDictionary.removeAll()
        indexedNameDictionary.removeAll()
        
        for drug in cloudDrugArray {
            for brandTerm in drug.brandNames {
                
                var substanceDose = String()
                var brand = String()
                
                if brandTerm == "" {
                    brand = drug.displayName
                } else {
                    brand = brandTerm + "®"
                }
                
                if  !indexedNameDictionary.keys.contains(where: { (key) -> Bool in
                    key == brandTerm })
                {
                    indexedNameDictionary[brand] = [drugIndex]
                } else {
                    if !indexedNameDictionary[brandTerm]!.contains(drugIndex)
                    {
                        (indexedNameDictionary[brand])?.append(drugIndex)
                    }
                }
                
                
                if drug.substances.count == 1 {
                    for doseIndex in 0..<drug.singleUnitDoses.count {
                        if drug.substances[0] != brand {
                            substanceDose = drug.substances[0] + " \(drug.singleUnitDoses[doseIndex])"
                            termsDictionary[brand + " (" + substanceDose + ")"] = drugIndex
                        } else {
                            termsDictionary[brand + " \(drug.singleUnitDoses[doseIndex])"] = drugIndex
                        }
                    }
                    
                } else {
                    guard drug.substances.count <= drug.singleUnitDoses.count else {
                        print("error while building termsDictionary - number of singleUnitDoses lower than number of substances in drug \(drug.displayName)")
                        drugIndex += 1
                        break
                    }
                    for index in 0..<drug.substances.count {
                        substanceDose = substanceDose + drug.substances[index] + " \(drug.singleUnitDoses[index])"
                        if index < (drug.substances.count - 1) { substanceDose = substanceDose + " with " }
                    }
                    termsDictionary[brand + " (" + substanceDose + ")"] = drugIndex
                    substanceDose = ""
                }
            }
            
            for substance in drug.substances {
                if  !indexedNameDictionary.keys.contains(where: { (key) -> Bool in
                    key == substance })
                {
                    indexedNameDictionary[substance] = [drugIndex]
                } else {
                    if !indexedNameDictionary[substance]!.contains(drugIndex)
                    {
                        (indexedNameDictionary[substance])?.append(drugIndex)
                    }
                }
                
            }
            
            drugIndex += 1
        }
        
        print("cloud drug termsDictionary updated")
        print(termsDictionary)
        print(indexedNameDictionary)
    */
    }
 
}

let drugFormularyGlobal = DrugDictionary()



