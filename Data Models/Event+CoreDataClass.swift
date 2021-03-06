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
    
    override public func awakeFromInsert() {
        
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = "dd.MM.yy - HH:mm:ss"
        let uniqueRecordID = "\(UIDevice.current.name) " + formatter.string(from: Date())
        self.urid = uniqueRecordID
        //self.setPrimitiveValue(uniqueRecordID, forKey: urid!)
        
    }

    
    func graphicDuration(scale: TimeInterval) -> CGFloat? {
        
        if (duration?.doubleValue ?? 0) > 0 {
            return CGFloat(duration!.doubleValue / scale)
        }
        return nil
    }
    
    func medEventRect(scale: TimeInterval) -> CGRect {
        
        var rect: CGRect!
        
        if (duration?.doubleValue ?? 0) > 0 {
            var width = CGFloat(duration!.doubleValue / scale)
            if width < medBarHeight {
                width = medBarHeight
            }
            rect = CGRect(x: 0, y: -medBarHeight - 3, width: width, height: medBarHeight)
        } else {
            rect = CGRect(x: -medBarHeight/2, y: -medBarHeight - 3, width: medBarHeight, height: medBarHeight)
        }
        return rect
    }
    
    func nonScoreEventRect(scale: TimeInterval) -> CGRect {
        
        return CGRect(x: -medBarHeight/2, y: -eventDiamondSize - 2, width: eventDiamondSize * 4/5, height: eventDiamondSize)

    }


}
