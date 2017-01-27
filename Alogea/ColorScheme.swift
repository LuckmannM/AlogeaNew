//
//  var swift
//  Alogea
//
//  Created by mikeMBP on 12/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit

let colorScheme = ColorScheme()

class ColorScheme {
    
    let darkBlue = UIColor(colorLiteralRed: 96/255, green: 129/255, blue: 172/255, alpha: 1.0)
    let lightBlue = UIColor(colorLiteralRed: 78/255, green: 109/255, blue: 156/255, alpha: 1.0)
    let lightGray = UIColor(colorLiteralRed: 232/255, green: 239/255, blue: 231/255, alpha: 1.0)
    var gradientGreen = UIColor(colorLiteralRed: 22/255, green: 238/255, blue: 133/255, alpha: 1.0)
    var earthGreen = UIColor(colorLiteralRed: 106/255, green: 97/255, blue: 60/255, alpha: 1.0)
    var gradientYellow = UIColor(colorLiteralRed: 251/255, green: 247/255, blue: 118/255, alpha: 1.0)
    var gradientOrange = UIColor(colorLiteralRed: 255/255, green: 161/255, blue: 34/255, alpha: 1.0)
    var gradientRed = UIColor(colorLiteralRed: 151/255, green: 60/255, blue: 56/255, alpha: 1.0)
    var seaGreen = UIColor(colorLiteralRed: 113/255, green: 180/255, blue: 174/255, alpha: 1.0)
    var lightViolet = UIColor(colorLiteralRed: 212/255, green: 122/255, blue: 156/255, alpha: 1.0)
    var darkViolet = UIColor(colorLiteralRed: 171/255, green: 105/255, blue: 138/255, alpha: 1.0)
    
    let drugRowGreenGray = UIColor(colorLiteralRed: 211/255, green: 218/255, blue: 202/255, alpha: 1.0)
    let drugRowWhite = UIColor(colorLiteralRed: 235/255, green: 235/255, blue: 235/255, alpha: 1.0)
    
    let lightYellow = UIColor(colorLiteralRed: 249/255, green: 246/255, blue: 195/255, alpha: 1.0)
    let white = UIColor.white

    class func sharedInstance() -> ColorScheme {
        return colorScheme
    }
    
}
