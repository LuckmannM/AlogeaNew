//
//  GraphContainerView.swift
//  Alogea
//
//  Created by mikeMBP on 12/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class GraphContainerView: UIView {

    
    @IBOutlet var floatingMenuView: FloatingMenuView!
    @IBOutlet weak var graphView: GraphView!
    
    var eventsController = EventsDataController.sharedInstance()
    var recordTypesController = RecordTypesController.sharedInstance()
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        print("graphViewContainer override init")
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("graphViewContainer init coder")

    }

    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
