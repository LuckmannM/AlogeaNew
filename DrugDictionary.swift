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
    
    var selectedDrugIndex: Int?
    var selectedDrugIndexForNamePicker: Int?
    var inAppStore: InAppStore!
    
    var termsDictionary = Dictionary<String, Int>() // this contains specific terms with indexes related to drug in cloudDrugArray, used for the NewDrug name row dropDown menu for selection
    var drugSelectionTerms = [String]() // contains strings only of the above specific terms to be displayed in NewDrug name namePicker
    var indexedNameDictionary = [String:[Int]]() // this contains all brandNames and substanceNames connected to the index in cloudDrugArray for return to NewDrug row name textField; it does contain a specfic name only once and the cloudDrugIndexes of drugs containing this term
    var matchingCloudDictionaryIndexes = [Int]()
    
    var namePickerIndexReferences = [Int]() // containing the cloudDrugArray indexes of drugNames passed to NewDrug.namePicker
    
    lazy var selectedNamePickerIndex: Int? = {
        
        return self.namePickerIndexReferences.index(where: {
            $0 == self.selectedDrugIndex
        })
    }()
    
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

        inAppStore = InAppStore.sharedInstance()
        
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
            key.lowercased().contains(name.lowercased())
        })
        print("matchingDrugNames____________")
        print("firstMatch is \(firstMatch)")
        
        let matchingKVPairs = indexedNameDictionary.lazy.filter({$0.0.lowercased().contains(name.lowercased())})
        print("matching for term: \(name)")
        print("matchingKVPairs are \(matchingKVPairs)")
        
        
        if firstMatch != nil && matchingKVPairs.first != nil {
            for index in (matchingKVPairs.first?.value)! {
                if firstMatch!.contains("®") {
                        selectedDrugIndex = index
                        // problem with this: if the brandName selected is not the [0] element in cloudDrugArray[index].brandNames then still brandName[0] is selected, which is the correct cloudDrug but under a different brandName than selected
                        print("index of currently selectedCloudDrug is \(selectedDrugIndex)")
                        print("currently selectedCloudDrug is \(cloudDrugArray[selectedDrugIndex!].displayName)")
                }
                else {
                    // this loop should find the cloudDrug in cloudDrugArray that contains the firstMatch substance as single substance only, rather than as one of multiple substances, so that the name displayed in NewDrug.name row matches the selected drug, either as brandname(above) or as single substance drug
                    if cloudDrugArray[index].substances$ == firstMatch! as String {
                        selectedDrugIndex = index
                        print("index of currently selectedCloudDrug is \(selectedDrugIndex)")
                        print("currently selectedCloudDrug is \(cloudDrugArray[selectedDrugIndex!])")
                        break
                    }
                }
            }
            // next there needs to be an exact match between cloudDrugArray[selectedDrugIndex] and the index of this drug in the drugSelectionTerms array; this index is passed on as selected drug of the drugSelectionTerms to the NewDrug.name drugNamePicker as array to chose from. When chosing the index number from this drugSelectionTerms array member is passed back and nneds to be translated to the cloudDrugArray inded number for the correct drug to be picked.
            
            matchingCloudDictionaryIndexes = [Int]()
            for (_, indexes) in matchingKVPairs {
                for index in indexes {
                    if !matchingCloudDictionaryIndexes.contains(index) {
                        matchingCloudDictionaryIndexes.append(index)
                    }
                }
            }
            // use these indexes instead of drugSelectionTerms for displaying the terms for drugNamePicker via CloudDrug.dictionaryTerms. Howver, this return [String] so this needs to be translated to individual string with maintained link to their CloudDrugDiciotnary index!
            
            print ("matchingCloudDrugIndexes are \(matchingCloudDictionaryIndexes)")
            
            return firstMatch! as String
        } else {
            selectedDrugIndex = nil
            return nil
        }
    }
    
    func namePickerTerms() -> [String] {
        
        var array = [String]()
        namePickerIndexReferences = [Int]()
        
        for index in matchingCloudDictionaryIndexes {
            for term in cloudDrugArray[index].dictionaryTerms {
                array.append(term)
                namePickerIndexReferences.append(index)
            }
        }
        
        return array
    }
    
    func returnSelectedPublicDrug(index: Int?) -> CloudDrug? {
        
        guard inAppStore.checkDrugFormularyAccess() == true else { return nil }
        
        
        // this is not right - either index = returned index of the drugSelectionTerms array
        // or selectedDrugIndex needs to be adapted when namePickerChoise is made in NewDrug
        
        guard index != nil else { return nil }
        
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
 
}

let drugFormularyGlobal = DrugDictionary()



