//
//  EventsDataController.swift
//  Alogea
//
//  Created by mikeMBP on 23/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class EventsData {
    
    
    lazy var stack: CoreDataStack = {
        return (UIApplication.shared.delegate as! AppDelegate).stack
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    let request = NSFetchRequest<Event>(entityName: "Event")
    

    
    
    init() {
//        allEvents = [Event]
        
    }
    
}
