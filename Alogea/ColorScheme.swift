//
//  ColorScheme.swift
//  Alogea
//
//  Created by mikeMBP on 12/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit

class ColorScheme {
    
    static var darkBlue: UIColor!
    static var lightBlue: UIColor!
    static var lightGray: UIColor!
    static var lightGreen: UIColor!
    static var earthGreen: UIColor!
    static var gradientYellow:UIColor!
    static var gradientOrange: UIColor!
    static var gradientRed: UIColor!
    static var seaGreen: UIColor!
    static var lightViolet: UIColor!
    static var darkViolet: UIColor!
    
    init() {
        ColorScheme.darkBlue = UIColor(colorLiteralRed: 96/255, green: 129/255, blue: 172/255, alpha: 1.0)
        ColorScheme.lightBlue = UIColor(colorLiteralRed: 78/255, green: 109/255, blue: 156/255, alpha: 1.0)
        ColorScheme.lightGray = UIColor(colorLiteralRed: 211/255, green: 210/255, blue: 188/255, alpha: 1.0)
        ColorScheme.lightGreen = UIColor(colorLiteralRed: 22/255, green: 238/255, blue: 133/255, alpha: 1.0)
        ColorScheme.earthGreen = UIColor(colorLiteralRed: 106/255, green: 97/255, blue: 60/255, alpha: 1.0)
        ColorScheme.gradientYellow = UIColor(colorLiteralRed: 251/255, green: 247/255, blue: 118/255, alpha: 1.0)
        ColorScheme.gradientOrange = UIColor(colorLiteralRed: 255/255, green: 161/255, blue: 34/255, alpha: 1.0)
        ColorScheme.gradientYellow = UIColor(colorLiteralRed: 251/255, green: 247/255, blue: 118/255, alpha: 1.0)
        ColorScheme.gradientRed = UIColor(colorLiteralRed: 151/255, green: 60/255, blue: 56/255, alpha: 1.0)
        ColorScheme.seaGreen = UIColor(colorLiteralRed: 114/255, green: 180/255, blue: 174/255, alpha: 1.0)
        ColorScheme.lightViolet = UIColor(colorLiteralRed: 212/255, green: 122/255, blue: 156/255, alpha: 1.0)
        ColorScheme.darkViolet = UIColor(colorLiteralRed: 171/255, green: 105/255, blue: 138/255, alpha: 1.0)
    }
    
    
}
