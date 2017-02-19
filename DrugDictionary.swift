//
//  DrugDictionary.swift
//  Alogea
//
//  Created by mikeMBP on 13/11/2016.
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
    
    var bestMatchingDrugIndex: Int?
    
    var namePickerArray = [String]() // containing the cloudDrugArray indexes of drugNames passed to NewDrug.namePicker
    
    init () {
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

        self.delegate = self
        
        fetchPublicRecords()
    }
    
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
                }
                self.modelUpdated()
                DispatchQueue.main.async() {
                    self.delegate?.modelUpdated()
                }
            }
        }
        )
        
    }
    
    func errorUpdating(error: NSError) {
        

    }
    
    func modelUpdated() {
        
    }
    
    // MARK: - NewDrug selection functions
    
    func matchingDrug(forSearchTerm: String) -> (String?,CloudDrug?) {
        
        var priority = 6
        
        // find all terms in brandNames and substances that begin with the searchTerm
        let (namePickerArray, drugsWithMatchesArray,_) = namePickerNames(forTerm: forSearchTerm)
        
        if let selectedDrugName = namePickerArray.filter( {
            $0.hasPrefix(forSearchTerm.lowercased())
         }).first {
        
            // now find best match among drugsWithMatches and this will be the selected drug
            for matchingDrugIndex in drugsWithMatchesArray  { // remember nil return!
                if let currentPriority = cloudDrugArray[matchingDrugIndex].matchPriorityOf(selectedName: selectedDrugName) {
                    if currentPriority < priority {
                        // what if two or more drugs have the same priority
                        priority = currentPriority
                        bestMatchingDrugIndex = matchingDrugIndex
                    }
                } else {
                    ErrorManager.sharedInstance().errorMessage(message: "MedDictionary Error 2", errorInfo: "cloudDrug with index \(matchingDrugIndex) returns  nil priority indicating no match, however there should be one!")
                }
            }
            return (selectedDrugName,cloudDrugArray[bestMatchingDrugIndex!])
        }
        return (nil,nil)
    }
    
    func namePickerNames(forTerm: String) -> ([String],[Int],Int?) {
        
        var matchingTermsArray = [[String]]()
        var drugsWithMatchesArray = [Int]()
        var selectedDrugIndexInNamePickerArray: Int?
        var index = 0
        
        // find all terms in brandNames and substances that begin with the searchTerm
        // build namePicker names array
        for drug in cloudDrugArray {
            let match = drug.namePickerNames(forSearchTerm: forTerm)
            if match != [] {
                // check if any of the matching terms in already included? If so don't attach but add cloudDrug
                drugsWithMatchesArray.append(index)
                var matchWithoutDuplicates = [String]()
                for term in match {
                    if !matchingTermsArray.joined().contains(term) {
                        matchWithoutDuplicates.append(term)
                    }
                }
                if matchWithoutDuplicates != [] { matchingTermsArray.append(matchWithoutDuplicates) }
            }
            index += 1
        }
        
        let namePickerArray = ((matchingTermsArray.joined()).map {$0.lowercased() }).sorted()
        
        if let selectedDrugName = namePickerArray.filter( {
            $0.hasPrefix(forTerm.lowercased())
         }).first {
            selectedDrugIndexInNamePickerArray = namePickerArray.index(of: selectedDrugName)
        }
        
        return (namePickerArray, drugsWithMatchesArray,selectedDrugIndexInNamePickerArray)
    }
     
}

let drugFormularyGlobal = DrugDictionary()



