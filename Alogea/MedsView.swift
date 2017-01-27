//
//  MedsView.swift
//  Alogea
//
//  Created by mikeMBP on 27/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

class MedsView: UIView {
    
    
    var graphView: GraphView!
    var helper: GraphViewHelper!
    var visibleRegularMeds: NSFetchedResultsController<DrugEpisode> {
        return MedicationController.sharedInstance().medsTakenBetween(startDate: graphView.minGraphDate, endDate: graphView.maxGraphDate)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(graphView: GraphView) {
        self.init()
        self.graphView = graphView
        self.helper = graphView.helper
        self.frame = graphView.bounds
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        for drug in visibleRegularMeds.fetchedObjects! {
            
            
            
        }

    }

}
