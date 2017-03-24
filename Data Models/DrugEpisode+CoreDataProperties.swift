//
//  DrugEpisode+CoreDataProperties.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import CoreData


extension DrugEpisode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrugEpisode> {
        return NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode");
    }

    @NSManaged public var attribute1: NSData?
    @NSManaged public var attribute2: NSData?
    @NSManaged public var attribute3: NSData?
    @NSManaged public var classes: NSData?
    @NSManaged public var doses: NSData?
    @NSManaged public var doseUnit: String?
    @NSManaged public var drugID: String?
    @NSManaged public var effectiveness: String?
    @NSManaged public var endDate: NSDate?
    @NSManaged public var frequency: Double
    @NSManaged public var ingredients: NSData?
    @NSManaged public var isCurrent: String?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var regularly: Bool
    @NSManaged public var reminders: NSData?
    @NSManaged public var sideEffects: NSData?
    @NSManaged public var startDate: NSDate?
    @NSManaged public var urid: String?

}
