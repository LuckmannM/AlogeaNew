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
        
        var array = self.substances[0]
        
        for index in 1..<self.substances.count {
            array += self.substances[index] + " "
        }
        return array
    }() // role is to select drugs in DrugDictionary.matchingDrugNames function to select single substance over multiple substance drugs
    lazy var dictionaryTerms:[String] = {
        
        var array = [String]()

        for brandTerm in self.brandNames {
            
            var substanceDose = String()
            var brand = String()
            var doses = String()
            
            if brandTerm == "" {
                brand = self.displayName
            } else {
                brand = brandTerm + "®"
            }
            
            if self.substances.count == 1 {
                for doseIndex in 0..<self.singleUnitDoses.count {
                    if self.substances[0] != brand {
                        substanceDose = self.substances[0] + " \(String(format: "%g",self.singleUnitDoses[doseIndex]))"
                        doses = "\(String(format: "%g", self.singleUnitDoses[doseIndex]))"
                        array.append(brand + " " + doses)
                    } else {
                        array.append(brand + " \(String(format: "%g", self.singleUnitDoses[doseIndex]))")
                    }
                }
                array.append(self.substances[0] + " \(String(format: "%g", self.singleUnitDoses[0]))")
                
            } else {
                guard self.substances.count <= self.singleUnitDoses.count else {
                    print("error in CloudDrug.dictionaryTerms - number of singleUnitDoses lower than number of substances in drug \(self.displayName)")
                    break
                }
                for index in 0..<self.substances.count {
                    substanceDose = substanceDose + self.substances[index] + " \(String(format: "%g", self.singleUnitDoses[index]))"
                    doses = doses + "\(String(format: "%g", self.singleUnitDoses[index]))"
                    if index < (self.substances.count - 1) {
                        substanceDose = substanceDose + " + "
                        doses = doses + "/"
                    }
                }
                array.append(brand + " (" + doses + ")")
                array.append(substanceDose)
                substanceDose = ""
                doses = ""
            }
        }
        return array
    }()
        
    init(record: CKRecord, database: CKDatabase) {
        
        //*** Build in safeguards if any of the fields in the Public database are empty!!!
        
        self.record = record
        self.database = database
        self.displayName = self.record.object(forKey: "displayName") as! String
        // make first character capital letter
        let nameFirstCharacter = (displayName as NSString).substring(to: 1).uppercased()
        let nameRestString = (displayName as NSString).substring(from: 1).lowercased()
        displayName = nameFirstCharacter + nameRestString
        
        if let names = self.record.object(forKey: "brandNames") as! [String]? {
            self.brandNames = names
        } else  { brandNames = [""] }
        
        if let substances = self.record.object(forKey: "medicineSubstances") as! [String]? {
            self.substances = substances
            for index in 0..<self.substances.count {
                self.substances[index] = self.substances[index].localizedCapitalized
            }
        } else { substances = [""] }
        
        if let objects = self.record.object(forKey: "classes") as! [String]? {
            self.classes = objects
        } else { classes = [""] }

        if let unit = self.record.object(forKey: "doseUnit") as! String? {
            self.doseUnit = unit
        } else { doseUnit = "" }

        if let reg = self.record.object(forKey: "regular") as! Int? {
            self.regular = reg
        } else { regular = 0 }

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
    
    
}
