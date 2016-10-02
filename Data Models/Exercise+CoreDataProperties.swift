//
//  Exercise+CoreDataProperties.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import CoreData


extension Exercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise");
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var duration: Double
    @NSManaged public var intensity: Double
    @NSManaged public var metricType: String?
    @NSManaged public var mectricValue: Double
    @NSManaged public var name: String?

}
