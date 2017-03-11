//
//  StatisticsController.swift
//  Alogea
//
//  Created by mikeMBP on 06/03/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import Foundation

class MedStats {
    
    var scoreTypeName = ""
    var medName = ""
    
    var mean: Double = 0.0
    var max: Double = 0.0
    var min: Double = 0.0
    var nowScore: Double = 0.0
    
    var moreThan5Pct: Double = 0.0
    var moreThan5TimePct: Double = 0
    var lessThan3Pct: Double = 0.0
    var lessThan3TimePct:Double = 0
    
    var numberOfScores = 0
    var computed = false
}

class EpisodeStats: MedStats {
    var startDate = Date()
    var endDate = Date()
    
    var numberOfMeds = 0
    var medNames = [String]()
}

class ScoreTypeStats: MedStats {
    
    var startDate = Date()
    var endDate = Date()

}


class StatisticsController {
    
    
    class func sharedInstance() -> StatisticsController {
        return statisticsController
    }
    
    
    // MARK: - stats for recordTypes
    func calculateScoreTypeStats() -> [ScoreTypeStats] {
        
        var scoreTypeStats = [ScoreTypeStats]()
        
        let scoreTypesWithSavedEvents = RecordTypesController.sharedInstance().returnRecordTypesWithSavedEvents()
        for type in scoreTypesWithSavedEvents {
            if let events = EventsDataController.sharedInstance().fetchSpecificEvents(name: type.name!, type: scoreEvent) {
                
                var scoreArray = [Double]()
                var over5Count: Double = 0
                var under3Count: Double = 0
                let newStats = ScoreTypeStats()
                
                newStats.scoreTypeName = type.name!
                
                for event in events {
                    scoreArray.append(event.vas as! Double)
                    if event.vas!.doubleValue > 5.0 {
                        over5Count += 1
                    } else if event.vas!.doubleValue < 3.0 {
                        under3Count += 1
                    }
                    
                }
                newStats.startDate = events.first!.date as! Date
                newStats.endDate = events.last!.date as! Date
                
                newStats.numberOfScores  = scoreArray.count
                newStats.max = scoreArray.max()!
                newStats.min = scoreArray.min()!
                newStats.mean = scoreArray.mean()
                
                newStats.moreThan5Pct = 100.0 * over5Count / Double(scoreArray.count)
                newStats.lessThan3Pct = 100.0 * under3Count / Double(scoreArray.count)
                
                let totalScoreTypeTime = (events.last?.date as! Date).timeIntervalSince(events.first?.date as! Date)
                
                if let episodeForScoreType = calculateScoreEpisodesOver5(events: events) {
                    var timeOver5 = TimeInterval()
                    for (start, end) in episodeForScoreType {
                        timeOver5 += end.timeIntervalSince(start)
                    }
                    newStats.moreThan5TimePct = 100 * timeOver5 / totalScoreTypeTime
                    scoreTypeStats.append(newStats)
                }
            }
        }
        return scoreTypeStats
        
    }
    
    private func calculateScoreEpisodesOver5(events:[Event]) -> [(Date,Date)]? {

        var datesArray = [(start: Date, end:Date)]()
        
        var index = 0
        
        repeat {
            // find next date with score>5 as eposide start
            var startDate: Date?
            var endDate: Date?
            for i in index..<events.count {
                //print("startDate loop:  event vas = \(events[i].vas), date = \(events[i].date)")
                if events[i].vas!.doubleValue > 5.0 {
                    if index == 0 {
                        startDate = events[i].date as Date?
                        break
                    }
                    else {
                        // earlier event with vas <= 5
                        let dScore = events[i].vas!.doubleValue - events[i-1].vas!.doubleValue
                        let dTime = events[i].date!.timeIntervalSince(events[i-1].date as! Date)
                        let scoreTo5 = events[i].vas!.doubleValue - 5.0
                        let timeTo5 = dTime * TimeInterval(abs(scoreTo5 / dScore))
                        startDate = events[i].date!.addingTimeInterval(-timeTo5) as Date?
                        index += 1
                        break
                    }
                }
            index += 1
            }
            
            guard startDate != nil else {
                // no event with vas>5 found
                return nil
            }
            
            // find next date when score<=5  as episode end
            for i in index..<events.count {
                // print("endDate loop: event vas = \(events[i].vas), date = \(events[i].date)")
                if events[i].vas!.doubleValue <= 5.0 {
                    // earlier event with vas > 5
                    let dScore = events[i-1].vas!.doubleValue - events[i].vas!.doubleValue
                    let dTime = events[i].date!.timeIntervalSince(events[i-1].date as! Date)
                    let scoreTo5 = events[i-1].vas!.doubleValue - 5.0
                    let timeTo5 = dTime * TimeInterval(abs(scoreTo5 / dScore))
                    endDate = events[i-1].date!.addingTimeInterval(timeTo5) as Date?
                    index = i + 1
                    break
                }
                index = i
            }
            
            if endDate == nil {
                // no event after start-event with vas<=5; adding 1 sec to last date to avoid long gaps until current date
                endDate = events.last!.date?.addingTimeInterval(1) as Date?
            }
            
            let newEpisode = (start: startDate!, end: endDate!)
            //print("new episode dates: \(newEpisode)")
            datesArray.append(newEpisode)
        } while index < events.count
        
        return datesArray
    }
    
    /*
    class func singleMedStats(forMedID: String) -> [(String, ScoreStats)]? {
        
        // returns a ScoreStats set for each scoreType: String
        let meds = MedicationController.sharedInstance().returnSingleMed(withID: forMedID)
        guard  (meds?.count ?? 0) > 0 else {
            return nil
        }
        
        let dates = meds![0].returnDatesForDrug() // [0] = startDate, [1] = endDate or now
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
    */
    
    // MARK: - stats for meds
    
    func singleMedStats(forMed: DrugEpisode) -> [MedStats]? {
        
        // returns a ScoreStats set for each scoreType: String
        
        let dates = forMed.returnDatesForDrug() // [0] = startDate, [1] = endDate or now
        let scoreTypesWithSavedEvents = RecordTypesController.sharedInstance().returnRecordTypesWithSavedEvents()
        var statsForScores = [MedStats]()
        
        print()
        print ("dates for med: \(forMed.nameVar) are \(dates)")
        
        for scoreType in scoreTypesWithSavedEvents {
            if let events = EventsDataController.sharedInstance().fetchEventsBetweenDates(type: scoreEvent, name: scoreType.name!, startDate: dates[0], endDate: dates[1]) {
                
                print ("there are \(events.count) scoreEvents of type \(scoreType.name) for this drug...")
                
                if let stats = calculateMedStats(withScoreEvents: events,forMed: forMed) {
                    statsForScores.append(stats)
                }
            }
        }
        
        if statsForScores.count > 0 {
            return statsForScores
        } else {
            return nil
        }
    }

    
    private func calculateMedStats(withScoreEvents: [Event], forMed: DrugEpisode ) -> MedStats? {
        
        guard withScoreEvents.count > 0 else {
            return nil
        }
        
        var scoreArray = [Double]()
        let stats = MedStats()
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
        
        stats.scoreTypeName = withScoreEvents[0].name ?? ""
        stats.medName = forMed.nameVar
        
        stats.max = scoreArray.max() ?? 0
        stats.min = scoreArray.min() ?? 0
        stats.mean = scoreArray.mean()
        
        stats.moreThan5Pct = Double(over5Count) / Double(scoreArray.count) * 100
        stats.lessThan3Pct = Double(under3Count) / Double(scoreArray.count) * 100
        
        var endingDate = Date()
        if forMed.endDate != nil {
            if forMed.endDate!.compare(Date()) == .orderedAscending {
                endingDate = forMed.endDate as! Date
            }
        }
        
//        let timeOnDrug = endingDate.timeIntervalSince(forMed.startDateVar)
//        if timeOnDrug > 0 {
//        }
        
        let totalScoreTime = (withScoreEvents.last!.date as! Date).timeIntervalSince(withScoreEvents.first!.date as! Date)
        //stats.moreThan5TimePct = timeOver5(startDate: forMed.startDateVar, endDate: endingDate,  scoreEvents: withScoreEvents)
        
        if let episodeForScoreType = calculateScoreEpisodesOver5(events: withScoreEvents) {
            var timeOver5 = TimeInterval()
            for (start, end) in episodeForScoreType {
                timeOver5 += end.timeIntervalSince(start)
            }
            stats.moreThan5TimePct = 100 * timeOver5 / totalScoreTime
        }
        
        stats.computed = true
        stats.numberOfScores  = withScoreEvents.count
        
        return stats
    }
    
    /*
    private func timeOver5(startDate: Date, endDate: Date, scoreEvents: [Event]) -> Double {
        // find all scoreEvents for different existing scores within start and endDate
        
        var timeAbove5: TimeInterval = 0

        for index in 0..<scoreEvents.count {
            if scoreEvents[index].vas!.doubleValue > 5.0 {
                print("calcTime: event>5:  \(scoreEvents[index].vas!)")
                if (index + 1) < scoreEvents.count  {
                    // further scoreEvents exists after this one
                    if scoreEvents[index + 1].vas!.doubleValue > 5.0 {
                        // next score is also above 5, add full time difference
                        timeAbove5 += scoreEvents[index+1].date!.timeIntervalSince(scoreEvents[index].date! as Date)
                        print("... next event also >5: \(scoreEvents[index+1].vas!)")
                        print("...... so time = \(timeAbove5)")
                    } else {
                       // next score is below 5
//                        let pitch = (scoreEvents[count+1].vas!.doubleValue - scoreEvents[count].vas!.doubleValue) / Double((scoreEvents[count+1].date!.timeIntervalSince(scoreEvents[count].date! as Date)))
//                        
//                        timeAbove5 += TimeInterval(scoreEvents[count].vas!.doubleValue - 5.0 / pitch)
                        let dTime = scoreEvents[index+1].date!.timeIntervalSince(scoreEvents[index].date! as Date)
                        let dScore = scoreEvents[index+1].vas!.doubleValue - scoreEvents[index].vas!.doubleValue
                        let to5 = scoreEvents[index].vas!.doubleValue - 5.0
                        timeAbove5 += TimeInterval(abs(to5 / dScore)) * dTime
                        print("... next event < 5 \(scoreEvents[index+1].vas!)")
                        print("...... time difference = \(dTime)")
                        print("...... score difference = \(dScore)")
                        print("...... scofre to 5 = \(to5)")
                        print("...... time>5 added = \(TimeInterval(abs(to5 / dScore)) * dTime)")

                    }
                }
                
            }
            else {
                // this score is below 5 but check wether next is above
                print("calcTime: event<=5:  \(scoreEvents[index].vas!)")
                if index + 1 < scoreEvents.count {
                    // there is another event after
                    if scoreEvents[index+1].vas!.doubleValue > 5.0 {
                        // the score of next event is above 5.0
                        let dTime = scoreEvents[index+1].date!.timeIntervalSince(scoreEvents[index].date! as Date)
                        let dScore = scoreEvents[index+1].vas!.doubleValue - scoreEvents[index].vas!.doubleValue
                        let to5 = 5.0 - scoreEvents[index+1].vas!.doubleValue
                        timeAbove5 += TimeInterval(abs(to5 / dScore)) / dTime
                        print("... next event < 5 \(scoreEvents[index+1].vas!)")
                        print("...... time difference = \(dTime)")
                        print("...... score difference = \(dScore)")
                        print("...... scofre to 5 = \(to5)")
                        print("...... time>5 added = \(TimeInterval(abs(to5 / dScore)) * dTime)")
                    }
                }
            }
            
        }
        
        let firstDate = scoreEvents[0].date
        let lastDate = scoreEvents.last?.date
        let totalScoreTime = lastDate?.timeIntervalSince(firstDate as! Date)
        
        return Double(100 * timeAbove5 / totalScoreTime!)
    }
 
     */
    
    // MARK: - Episode stats
    
    func episodeStats() -> [EpisodeStats]? {
        
        var stats: [EpisodeStats]?
        let defaultStartDate = Date().addingTimeInterval(-24*3600)
        
        // 1. get startDate from earliest event (scoreEvent or medEvent) or regMed startDates
        var eventsMinDate:Date = EventsDataController.sharedInstance().earliestScoreOrMedEventDate() ?? defaultStartDate
        if let firstDate = MedicationController.sharedInstance().returnFirstRegMedStartDate() {
            if eventsMinDate.compare(firstDate) == .orderedDescending {
                eventsMinDate = firstDate
            }
        }
        
        // 2. get all medEvents and regMeds start- and endDates (if any or now) together ordered ascending
        var datesArray = [eventsMinDate]
        
        if let medEvents = EventsDataController.sharedInstance().fetchAllMedEvents() {
            for event in medEvents {
                datesArray.append(event.date as! Date)
                if event.duration != nil {
                    datesArray.append(event.date!.addingTimeInterval(event.duration as! TimeInterval) as Date)
                }
            }
        }
        
        let regMedsFRC = MedicationController.sharedInstance().regMedsFRC
        if (regMedsFRC.fetchedObjects?.count ?? 0) > 0 {
            for regMed in regMedsFRC.fetchedObjects! {
                datesArray.append(regMed.startDate as! Date)
                
                if regMed.endDate != nil {
                    if regMed.endDate?.compare(Date()) == .orderedDescending {
                        datesArray.append(regMed.endDate as! Date)
                    }
                }
            }
        }
        
        if datesArray.count > 0 {
            datesArray.sort(by: {$0.compare($1) == ComparisonResult.orderedAscending})
        } else {
            // no events or regMeds present
            return stats
        }
        
        // 3. form episodes from these dates, with startDate and endDate back to back until nowDate
        var count = 1
        for aDate in datesArray {
            let newEpisode = EpisodeStats()
            newEpisode.startDate = aDate
            if count > datesArray.count {
                newEpisode.endDate = Date()
            } else {
                newEpisode.endDate = datesArray[count + 1]
            }
            
            count += 1
        }
        
        // 4. create EpisodeStats for each episode and calculate stats, which meds etc
        let scoreEvents = EventsDataController.sharedInstance().fetchAllScoreEvents()
        
        
        return stats
        
    }
    
}

let statisticsController = StatisticsController()
