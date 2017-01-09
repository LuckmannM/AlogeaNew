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
//    var inAppStore: InAppStore!
    
//    var termsDictionary = Dictionary<String, Int>() // this contains specific terms with indexes related to drug in cloudDrugArray, used for the NewDrug name row dropDown menu for selection
//    var drugSelectionTerms = [String]() // contains strings only of the above specific terms to be displayed in NewDrug name namePicker
//    var indexedNameDictionary = [String:[Int]]() // this contains all brandNames and substanceNames connected to the index in cloudDrugArray for return to NewDrug row name textField; it does contain a specfic name only once and the cloudDrugIndexes of drugs containing this term
//    var matchingCloudDictionaryIndexes = [Int]()
    
    var namePickerArray = [String]() // containing the cloudDrugArray indexes of drugNames passed to NewDrug.namePicker
    
//    lazy var selectedNamePickerIndex: Int? = {
//        
//        return self.namePickerIndexReferences.index(where: {
//            $0 == self.selectedDrugIndex
//        })
//    }()
    
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

//        inAppStore = InAppStore.sharedInstance()
        
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
    
//    func drugFormularyDisplayNamesArray() -> [String] {
//        
//        var nameArray = [String]()
//        
//        for drug in cloudDrugArray {
//            nameArray.append(drug.displayName.lowercased())
//        }
//        
//        return nameArray
//
//    }
//    
//    func drugFormularyClassesArray() -> [[String]] {
//        
//        var classesArray = [[String]]()
//        
//        for drug in cloudDrugArray {
//            classesArray.append(drug.classes)
//        }
//        
//        return classesArray
//    }
    
    func errorUpdating(error: NSError) {
        
        print("error loading DrugDictionary: \(error)")
        // *** consider displaying an alert prompting user to log into iCloud
        
    }
    
    func modelUpdated() {
        
//        var drugIndex = 0
//        
//        termsDictionary.removeAll()
//        indexedNameDictionary.removeAll()
//        
//        for drug in cloudDrugArray {
//            
//            // build termDictionary: for NewDrug.name dropDown menu, all terms containing a string
//            for term in drug.dictionaryTerms {
//                termsDictionary[term] = drugIndex
//            }
//            
//            // build indexedNameDictionary: for NewDrug.name textField, only one matching term for display
//            for brandTerm in drug.brandNames {
//                
//                var brand = String()
//                if brandTerm == "" {
//                    brand = drug.displayName
//                } else {
//                    brand = brandTerm + "®"
//                }
//                
//                if  !indexedNameDictionary.keys.contains(where: { (key) -> Bool in
//                    key == brandTerm })
//                {
//                    indexedNameDictionary[brand] = [drugIndex]
//                } else {
//                    if !indexedNameDictionary[brandTerm]!.contains(drugIndex)
//                    {
//                        (indexedNameDictionary[brand])?.append(drugIndex)
//                    }
//                }
//                
//            }
//            
//            for substance in drug.substances {
//                if  !indexedNameDictionary.keys.contains(where: { (key) -> Bool in
//                    key == substance })
//                {
//                    indexedNameDictionary[substance] = [drugIndex]
//                } else {
//                    if !indexedNameDictionary[substance]!.contains(drugIndex)
//                    {
//                        (indexedNameDictionary[substance])?.append(drugIndex)
//                    }
//                }
//                
//            }
//            
//            drugIndex += 1
//        }
        
        //
        //        print("cloud drug termsDictionary updated")
        //        print("termsDictionary:")
        //        for term in termsDictionary {
        //            print(term)
        //        }
        //        print("")
        //        print("indexedNameDictionary :")
        //        for term in indexedNameDictionary {
        //            print(term)
        //        }
    }
    
    // MARK: - NewDrug selection functions
    
    func matchingDrug(forSearchTerm: String) -> (String?,CloudDrug?) {
        
        var priority = 6
        
        // find all terms in brandNames and substances that begin with the searchTerm
        let (namePickerArray, drugsWithMatchesArray,_) = namePickerNames(forTerm: forSearchTerm)
        
        if let selectedDrugName = namePickerArray.filter( {
            $0.hasPrefix(forSearchTerm.lowercased())
         }).first {
        
            print("drugsWithMatchesArray is \(drugsWithMatchesArray)")
            // now find best match among drugsWithMatches and this will be the selected drug
            for matchingDrugIndex in drugsWithMatchesArray  { // remember nil return!
                if let currentPriority = cloudDrugArray[matchingDrugIndex].matchPriorityOf(selectedName: selectedDrugName) {
                    if currentPriority < priority {
                        // what if two or more drugs have the same priority
                        priority = currentPriority
                        bestMatchingDrugIndex = matchingDrugIndex
                    }
                    print("cloudDrug with index \(matchingDrugIndex) returns priority \(priority)")
                } else {
                    print("cloudDrug with index \(matchingDrugIndex) returns  nil priority indicating no match, however there should be one!")
                    
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
            print("namePickerNames for term '\(forTerm)' are \(namePickerArray)")
        
        if let selectedDrugName = namePickerArray.filter( {
            $0.hasPrefix(forTerm.lowercased())
         }).first {
            selectedDrugIndexInNamePickerArray = namePickerArray.index(of: selectedDrugName)
        }
        
        print("position of selectedDrug in namePickerArray = \(selectedDrugIndexInNamePickerArray)")

        return (namePickerArray, drugsWithMatchesArray,selectedDrugIndexInNamePickerArray)
    }
    
//    func drugFromNamePickerList(withIndex: String) -> CloudDrug {
//        
//        let name = namePickerArray[withIndex]
//    }
    
 
}

let drugFormularyGlobal = DrugDictionary()



