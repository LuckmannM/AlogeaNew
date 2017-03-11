//
//  DigitsFromString.swift
//  Alogea
//
//  Created by mikeMBP on 10/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import Foundation


extension String {
    
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}

extension Array {
    
    func mean() -> Double {
        
        guard self.count > 0 else {
            return 0.0
        }
        
        var sum:Double = 0.0
        
        for element in self {
            sum += element as! Double
        }
        
        return sum / Double(self.count)
    }
      
}
