//
//  MainViewButton.swift
//  Alogea
//
//  Created by mikeMBP on 14/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class MainViewButton: UIButton {
    
    var colors: ColorScheme!
    weak var containingView: MVButtonView!
        
    convenience init(frame: CGRect, containingView: MVButtonView) {
        self.init(frame: frame)
        self.backgroundColor = UIColor.clear
        colors = ColorScheme.sharedInstance()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    
    /*
    override func draw(_ rect: CGRect) {
    }
    */
}
