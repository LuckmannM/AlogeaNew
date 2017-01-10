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
