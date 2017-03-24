//
//  RecordType+CoreDataClass.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData


public class RecordType: NSManagedObject {
    
    override public func awakeFromInsert() {
        
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = "dd.MM.yy - HH:mm:ss"
        let uniqueRecordID = "\(UIDevice.current.name) " + formatter.string(from: Date())
        
        self.urid = uniqueRecordID
        
        //self.setPrimitiveValue(uniqueRecordID, forKey: urid!)
        
    }


}
