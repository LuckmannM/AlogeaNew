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
    
    init(record: CKRecord, database: CKDatabase) {
        
        //*** Build in safeguards if any of the fields in the Public database are empty!!!
        
        self.record = record
        self.database = database
        self.displayName = self.record.object(forKey: "displayName") as! String
        // make first character capital letter
        let nameFirstCharacter = (displayName as NSString).substring(to: 1).uppercased()
        let nameRestString = (displayName as NSString).substring(from: 1).lowercased()
        displayName = nameFirstCharacter + nameRestString
        self.substances = self.record.object(forKey: "ingredients") as! [String]
        self.classes = self.record.object(forKey: "classes") as! [String]
        self.doseUnit = self.record.object(forKey: "doseUnit") as! String
        self.regular = self.record.object(forKey: "regular") as! Int
        self.startingDoseInterval = TimeInterval(self.record.object(forKey: "startingDoseInterval") as! Double) * 3600
        
        if self.record.object(forKey: "maxSingleDoses") != nil {
            self.maxSingleDoses = self.record.object(forKey: "maxSingleDoses") as? [Double]
        }
        
        if self.record.object(forKey: "maxDailyDoses") != nil {
            self.maxDailyDoses = self.record.object(forKey: "maxDailyDoses") as? [Double]
        }
        
        if self.record.object(forKey: "startingDoses") != nil {
            self.startingDoses = self.record.object(forKey: "startingDoses") as! [Double]
        }
        
        if self.record.object(forKey: "recommendDuration") != nil {
            self.recommendDuration = TimeInterval((self.record.object(forKey: "recommendDuration") as? Double)!) * 24*3600
            
        }
        
    }
    
    
}
