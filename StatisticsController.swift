//
//  StatisticsController.swift
//  Alogea
//
//  Created by mikeMBP on 06/03/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import Foundation

struct ScoreStats {
    var mean = Double()
    var max = Double()
    var min = Double()
    var nowScore = Double()
    
    var moreThan5Pct = Double()
    var moreThan5TimePct = TimeInterval()
    var lessThan3Pct = Double()
    var lessThan3TimePct = TimeInterval()
}


class StatisticsController {
    
//    var statisticsSet = [ScoreStats]()
//    let medsController = MedicationController.sharedInstance()
//    let eventsController = EventsDataController.sharedInstance()
    
    class func sharedInstance() -> StatisticsController {
        return statisticsController
    }
    
    
    class func singleMedStats(forMedID: String) -> [(String, ScoreStats)]? {
        
        guard let meds = MedicationController.sharedInstance().returnSingleMed(withID: forMedID) else {
            return nil
        }
        
        let dates = meds[0].returnDatesForDrug() // [0] = startDate, [1] = endDate or now
        let scoreTypesWithSavedEvents = RecordTypesController.sharedInstance().returnRecordTypesWithSavedEvents()
        var statsForScores:[(String, ScoreStats)]?
        
        for scoreType in scoreTypesWithSavedEvents {
            let scoreName = scoreType.name!
            var stats:ScoreStats?
            if let events = EventsDataController.sharedInstance().fetchEventsBetweenDates(type: scoreEvent, name: scoreType.name!, startDate: dates[0], endDate: dates[1]) {
                stats = calculateStats(withScoreEvents: events)
                statsForScores?.append((scoreName, stats!))
            }
        }
        return statsForScores
    }
    
    class func calculateStats(withScoreEvents: [Event]) -> ScoreStats {
        
        var scoreArray = [Double]()
        var stats = ScoreStats()
        var over5Count = 0
        var under3Count = 0

        for event in withScoreEvents {
            scoreArray.append(event.vas as! Double)
            if event.vas!.doubleValue > 5.0 {
                over5Count += 1
            } else if event.vas!.doubleValue < 3.0 {
                under3Count += 1
            }
        }
        
        stats.max = scoreArray.max()!
        stats.min = scoreArray.min()!
        
        stats.moreThan5Pct = Double(over5Count) / Double(scoreArray.count) * 100
        stats.lessThan3Pct = Double(under3Count) / Double(scoreArray.count) * 100
        
        
        return stats
        
    }
    
}

let statisticsController = StatisticsController()
