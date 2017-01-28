//
//  Event+CoreDataClass.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData


public class Event: NSManagedObject {
    
    func graphicDuration(scale: TimeInterval) -> CGFloat? {
        
        if (duration ?? 0) > 0 {
            return CGFloat(duration / scale)
        }
        return nil
    }

}
