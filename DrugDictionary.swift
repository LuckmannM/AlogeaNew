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

protocol PublicDrugFormularyDelegate {
    func errorUpdating(error: NSError)
    func modelUpdated()
}

class DrugDictionary {
    
    class func sharedInstance() -> DrugDictionary {
        return drugFormularyGlobal
    }
    
    var iCloudContainer: CKContainer!
    var publicDB : CKDatabase!
    var cloudDrugArray = [CloudDrug]()
    var iCloudStatus: CKAccountStatus!
    
    var delegate: PublicDrugFormularyDelegate?
    
    var selectedDrugIndex: Int?
    var inAppStore: InAppStore!
    
    init () {
        iCloudContainer = CKContainer.default()
        //        iCloudContainer = CKContainer(identifier: "iCloud.co.uk.apptoolfactory.NewContainer")
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
        
        fetchAllRecords()
    }
    
    func fetchRecordsByName(name: String) {
        let searchForName = NSPredicate(format: "(displayName = %@)", name)
        let databaseQuery = CKQuery(recordType: "CloudMedicinesDictionary", predicate: searchForName)
        
        publicDB.perform(databaseQuery, inZoneWith: nil, completionHandler: { results, error in
            if error != nil {
                DispatchQueue.main.async() {
                    self.delegate?.errorUpdating(error: error as! NSError)
                    print("DrugDictionary - fetchRecordsByName. performQuery, error loading: \(error)")
                }
            } else {
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
    
    func fetchAllRecords() {
        let searchForAll = NSPredicate(value: true)
        let databaseQuery = CKQuery(recordType: "CloudMedicinesDictionary", predicate: searchForAll)
        
        publicDB.perform(databaseQuery, inZoneWith: nil, completionHandler: { results, error in
            if error != nil {
                DispatchQueue.main.async() {
                    self.delegate?.errorUpdating(error: error as! NSError)
                    print("DrugDictionary - fetchAllRecords. performQuery error loading: \(error)")
                }
            } else {
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
    
    func drugFormularyNameArray() -> [String] {
        
        var nameArray = [String]()
        
        //        print("public drug array contain \(cloudDrugArray)")
        
        for drug in cloudDrugArray {
            nameArray.append(drug.displayName.lowercased())
        }
        
        //        print("public drug array names contain \(nameArray)")
        
        return nameArray
    }
    
    func drugFormularyIngredientArray() -> [[String]] {
        
        var ingredientArray = [[String]]()
        
        for drug in cloudDrugArray {
            ingredientArray.append(drug.substances)
        }
        
        return ingredientArray
    }
    
    func drugFormularyClassesArray() -> [[String]] {
        
        var classesArray = [[String]]()
        
        for drug in cloudDrugArray {
            classesArray.append(drug.classes)
        }
        
        return classesArray
    }
    
    func matchingDrugNames(name: String) -> [String] {
        
        
        if inAppStore.checkDrugFormularyAccess() == false {
            return [""]
        }
        
        // returns all names containing the string characters. these can be one or two -> lots of names found
        // when only one or two chracters are entered in name, then matchingName[0] is alphabetically the first
        // should,however, be one that also starts with the character in name! - this is ensured by AnchoredSearch
        //        let matchingNames = drugFormularyNameArray().filter({$0.rangeOfString(name.lowercaseString,options: NSStringCompareOptions.AnchoredSearch) != nil})
        //        if matchingNames.count > 0 {
        //            selectedDrugIndex = drugFormularyNameArray().indexOf(matchingNames[0])
        //            return cloudDrugArray[selectedDrugIndex!].name
        //        }
        //        else {return "" }
        
        //        var matchingDrugArray = [String]()
        //
        //        for name in matchingNames {
        //            matchingDrugArray.append(name)
        //        }
        //
        //        return matchingDrugArray
        
        //        print("DrugDictionary Name Array contains \(drugFormularyNameArray().filter({$0.rangeOfString(name.lowercaseString,options: NSStringCompareOptions.AnchoredSearch) != nil}))")
        
        let matchingDrugArray = drugFormularyNameArray().filter({$0.range(of: name.lowercased(),options: NSString.CompareOptions.anchored) != nil})
        
        if matchingDrugArray.count > 0 {
            selectedDrugIndex = drugFormularyNameArray().index(of: matchingDrugArray[0])
        }
        
        //        var firstCapitalNameArray = [String]()
        //        for drug in matchingDrugArray {
        //            firstCapitalNameArray.append((drug as NSString).substringToIndex(1).uppercaseString + (drug as NSString).substringFromIndex(1))
        //        }
        
        return  matchingDrugArray
        
    }
    
    func returnSelectedPublicDrug(name: String, index: Int = -1) -> CloudDrug? {
        
        // return first object '[0]' if no other index chosen, e.g. from NewDrugTVC by user choice via drugNamePicker
        
        
        if inAppStore.checkDrugFormularyAccess() == false { return nil }
        
        let matchingDrugArray = matchingDrugNames(name: name.lowercased())
        var matchingDrugIndexes = [Int]()
        
        for drug in matchingDrugArray {
            matchingDrugIndexes.append(drugFormularyNameArray().index(of: drug)!)
        }
        
        
        if index == -1  {
            return cloudDrugArray[matchingDrugIndexes[0]]
        }
        else if index < cloudDrugArray.count { return cloudDrugArray[matchingDrugIndexes[index]] }
        else { return nil }
    }
    
    func modelUpdated() {
        
    }
}

let drugFormularyGlobal = DrugDictionary()



