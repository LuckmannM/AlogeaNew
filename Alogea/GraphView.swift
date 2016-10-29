//
//  GraphView.swift
//  Alogea
//
//  Created by mikeMBP on 23/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class GraphView: UIView {
    
    let eventsDataController = EventsDataController.sharedInstance()
    var graphPoints: [CGPoint]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        graphPoints = [CGPoint]()
        
        if eventsDataController.selectedScoreEventsFRC.fetchedObjects?.count == 0 {
            eventsDataController.createExampleEvents()
            eventsDataController.printSelectedScoreEventDates()
        }
        
        print("graphView init coder")
        graphPoints = calculateGraphPoints()
        
    }
    

//    override func draw(_ rect: CGRect) {
//        // Drawing code
//        graphPoints = eventsDataController.lineGraphData(forViewSize: frame.size, minDate: eventsDataController.minDisplayDate, displayedTimeSpan: eventsDataController.displayTimeInterval)
//        
//    }
    
    func calculateGraphPoints() -> [CGPoint] {
        
        let points = [CGPoint]()
        
        guard let scoreEventsDict = eventsDataController.graphData() else {
            return points
        }
        
        for scoreEvent in scoreEventsDict {
            print("eventDict \(scoreEvent)")
        
        }
        
        return points
    }

}
