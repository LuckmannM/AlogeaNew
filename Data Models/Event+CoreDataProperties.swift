//
//  Event+CoreDataProperties.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event");
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var duration: NSNumber?
    @NSManaged public var bodyLocation: String?
    @NSManaged public var locationImage: NSObject?
    @NSManaged public var name: String?
    @NSManaged public var note: String?
    @NSManaged public var outcome: String?
    @NSManaged public var type: String?
    @NSManaged public var vas: NSNumber?

}
