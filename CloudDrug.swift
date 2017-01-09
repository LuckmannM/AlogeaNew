//
//  CloudDrug.swift
//  Alogea
//
//  Created by mikeMBP on 13/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import CloudKit

class CloudDrug {
    var record: CKRecord!
    weak var database: CKDatabase!
    
    var brandNames: [String]!
    var classes: [String]!
    var displayName: String!
    var maxDailyDoses: [Double]?
    var maxSingleDoses: [Double]?
    var substances: [String]!
    var doseUnit: String!
    var startingDoseInterval: TimeInterval! // stored as hours!
    var recommendDuration: TimeInterval? // stored as days
    var startingDoses: [Double]!
    var singleUnitDoses:[Double]!
    var regular: Int!
    
    lazy var substances$: String = {
        // role is to select drugs in DrugDictionary.matchingDrugNames function to select single substance over multiple substance drugs
        var array = self.substances[0]
        
        for index in 1..<self.substances.count {
            array += self.substances[index] + " "
        }
        return array
    }()
  
    lazy var brands$: String = {
        // role is to select drugs in DrugDictionary.matchingDrugNames function to select single substance over multiple substance drugs
        var array = self.brandNames[0]
        
        for index in 1..<self.brandNames.count {
            array += self.brandNames[index] + "® "
        }
        return array
    }()
    
//    lazy var dictionaryTerms:[String] = {
//        
//        var array = [String]()
//
//        // ***  the entire loop requires repated .contains checks which may slow performance; review and check better options
//        for brandTerm in self.brandNames {
//            // if the CloudDashboard drug doesn't have a brandName a cloudDrug will be intialised with [""] as brandNames
//            var substanceDose = String()
//            var brand = String()
//            var doses = String()
//            
//            if brandTerm == "" {
//                brand = self.displayName
//            } else {
//                brand = brandTerm + "®"
//            }
//            
//            if self.substances.count == 1 {
//                for doseIndex in 0..<self.singleUnitDoses.count {
//                    if self.substances[0] != brand {
//                        doses = "\(String(format: "%g", self.singleUnitDoses[doseIndex]))"
//                        array.append(self.substances[0] + " " + doses)
//                        array.append(brand + " \(String(format: "%g", self.singleUnitDoses[doseIndex]))")
//                    } else {
//                        array.append(brand + " \(String(format: "%g", self.singleUnitDoses[doseIndex]))")
//                    }
//                }
//                
//            
//            } else {
//                guard self.substances.count <= self.singleUnitDoses.count else {
//                    print("error in CloudDrug.dictionaryTerms - number of singleUnitDoses lower than number of substances in drug \(self.displayName)")
//                    break
//                }
//                for index in 0..<self.substances.count {
//                    substanceDose = substanceDose + self.substances[index] + " \(String(format: "%g", self.singleUnitDoses[index]))"
//                    doses = doses + "\(String(format: "%g", self.singleUnitDoses[index]))"
//                    if index < (self.substances.count - 1) {
//                        substanceDose = substanceDose + " + "
//                        doses = doses + "/"
//                    }
//                }
//                array.append(brand + " (" + doses + ")")
//                if !array.contains(substanceDose) {
//                    array.append(substanceDose)
//                }
//                substanceDose = ""
//                doses = ""
//            }
//        }
//        return array
//    }()
    
    // MARK: - Functions
        
    init(record: CKRecord, database: CKDatabase) {
        
        //*** Build in safeguards if any of the fields in the Public database are empty!!!
        
        self.record = record
        self.database = database
        self.displayName = (self.record.object(forKey: "displayName") as! String).localizedCapitalized
        self.brandNames = ((self.record.object(forKey: "brandNames") as? [String])?.sorted() ?? [])!
        self.substances = ((self.record.object(forKey: "medicineSubstances") as? [String]) ?? [])
        self.classes = ((self.record.object(forKey: "classes") as? [String]) ?? [])
        self.doseUnit = ((self.record.object(forKey: "doseUnit") as? String) ?? "")
        self.regular = ((self.record.object(forKey: "regular") as? Int) ?? 0)

        if let dI = self.record.object(forKey: "startingDoseEffectTime") as! Double? {
            self.startingDoseInterval = TimeInterval(dI * 3600)
        } else { startingDoseInterval = 0.0 }
        
        if self.record.object(forKey: "maxSingleDoses") != nil {
            self.maxSingleDoses = self.record.object(forKey: "maxSingleDoses") as? [Double]
        }
        
        if self.record.object(forKey: "maxDailyDoses") != nil {
            self.maxDailyDoses = self.record.object(forKey: "maxDailyDoses") as? [Double]
        }
        
        if self.record.object(forKey: "startingDoses") != nil {
            self.startingDoses = self.record.object(forKey: "startingDoses") as! [Double]
        }
        
        if self.record.object(forKey: "recommendedDuration") != nil {
            self.recommendDuration = TimeInterval((self.record.object(forKey: "recommendedDuration") as? Double)!) * 24*3600
        }
        // note - typo in cloudDataBase: singeUnitDoses instead of singleUnitDoses
        if self.record.object(forKey: "singeUnitDoses") != nil {
            self.singleUnitDoses = self.record.object(forKey: "singeUnitDoses") as? [Double]
        }
        
    }
    
    func substancesForSearch() -> String {
        
        var string = String()
        for substance in substances {
            string += substance.lowercased() + " "
        }
        return string
    }
    
    func substancesForDisplay() -> String {
        
        var string = substances[0]
        for index in 1..<substances.count {
            string += " + " + substances[index]
        }
        return string
    }
    
    func namePickerNames(forSearchTerm: String) -> [String] {
        
        var array = [String]()
        
        for substance in substances {
            if substance.lowercased().hasPrefix(forSearchTerm.lowercased()) {
                // if a substance that begins with the searchterm is found then attach all substance names combined
                array.append(substancesForDisplay())
                // also attached all brandNames as these contain the searchTerm substance
                if brandNames != nil {
                    for name in brandNames! {
                        array.append(name)
                    }
                }
            }
        }
        
        // if a substance has been found then all brandNames are included already
        // if no substance matches then check wether individual brandNames match
        if array != [] { return array }
        
        // combined substance term 'a+b' may be passed on after selection in namePicker
        if substancesForDisplay().lowercased().hasPrefix(forSearchTerm.lowercased()) {
            array.append(substancesForDisplay())
            // also attached all brandNames as these contain the searchTerm substance
            if brandNames != nil {
                for name in brandNames! {
                    array.append(name)
                }
            }
        }
        
        if array != [] { return array }
        
        for name in brandNames! {
            if name.lowercased().hasPrefix(forSearchTerm.lowercased()) {
                array.append(name)
            }
        }
        
        return array
    }
    
    func matchPriorityOf(selectedName: String) -> Int? {
        
        //match in brandNames = highest priority for == and one lower for 'begins with'
        for brand in brandNames! {
            if brand.lowercased() == selectedName.lowercased() {
                return 0
            }
            if brand.lowercased().hasPrefix(selectedName.lowercased()) {
                return 1
            }
        }
        
        // selectedName may be a substance combination term 'a+b' after selection in namePicker
        if substancesForDisplay().lowercased() == selectedName.lowercased() {
            return 0
        }
        if substancesForDisplay().lowercased().hasPrefix(selectedName.lowercased()) {
            return 2
        }
        if substancesForDisplay().lowercased().contains(selectedName.lowercased()) {
            return 3
        }
        
        
        return nil
    }
    
    
}
