//
//  RecordType+CoreDataProperties.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import CoreData


extension RecordType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecordType> {
        return NSFetchRequest<RecordType>(entityName: "RecordType");
    }

    @NSManaged public var dateCreated: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var minScore: NSNumber?
    @NSManaged public var maxScore: NSNumber?
    @NSManaged public var urid: String?

}
