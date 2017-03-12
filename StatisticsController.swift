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
                }
                
                if let episodes = calculateScoreEpisodesUnder3(events: events) {
                    var timeUnder3 = TimeInterval()
                    for (start, end) in episodes {
                        timeUnder3 += end.timeIntervalSince(start)
                    }
                    newStats.lessThan3TimePct = 100 * timeUnder3 / totalScoreTypeTime
                }
                scoreTypeStats.append(newStats)
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
                return datesArray
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
    
    private func calculateScoreEpisodesUnder3(events:[Event]) -> [(Date,Date)]? {
        
        var datesArray = [(start: Date, end:Date)]()
        
        var index = 0
        
        repeat {
            // find next date with score<3 as eposide start
            var startDate: Date?
            var endDate: Date?
            for i in index..<events.count {
                // print("startDate loop:  event vas = \(events[i].vas), date = \(events[i].date)")
                if events[i].vas!.doubleValue < 3.0 {
                    if index == 0 {
                        startDate = events[i].date as Date?
                        break
                    }
                    else {
                        // earlier event with vas > 3
                        let dScore = events[i-1].vas!.doubleValue - events[i].vas!.doubleValue
                        let dTime = events[i].date!.timeIntervalSince(events[i-1].date as! Date)
                        let scoreFrom3 = 3.0 - events[i].vas!.doubleValue
                        let timeTo3 = dTime * TimeInterval(abs(scoreFrom3 / dScore))
                        startDate = events[i].date!.addingTimeInterval(-timeTo3) as Date?
                        index += 1
                        break
                    }
                }
                index += 1
            }
            
            guard startDate != nil else {
                // no event with vas<3 found
                return datesArray
            }
            
            // find next date when score>=3  as episode end
            for i in index..<events.count {
                // print("endDate loop: event vas = \(events[i].vas), date = \(events[i].date)")
                if events[i].vas!.doubleValue >= 3.0 {
                    // earlier event with vas > 5
                    let dScore = events[i-1].vas!.doubleValue - events[i].vas!.doubleValue
                    let dTime = events[i].date!.timeIntervalSince(events[i-1].date as! Date)
                    let scoreTo3 = events[i-1].vas!.doubleValue - 3.0
                    let timeTo3 = dTime * TimeInterval(abs(scoreTo3 / dScore))
                    endDate = events[i-1].date!.addingTimeInterval(timeTo3) as Date?
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
    
    // MARK: - stats for meds
    
    func singleMedStats(forMed: DrugEpisode) -> [MedStats]? {
        
        // returns a ScoreStats set for each scoreType: String
        
        let dates = forMed.returnDatesForDrug() // [0] = startDate, [1] = endDate or now
        let scoreTypesWithSavedEvents = RecordTypesController.sharedInstance().returnRecordTypesWithSavedEvents()
        var statsForScores = [MedStats]()
        
        for scoreType in scoreTypesWithSavedEvents {
            if let events = EventsDataController.sharedInstance().fetchEventsBetweenDates(type: scoreEvent, name: scoreType.name!, startDate: dates[0], endDate: dates[1]) {
                
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
        
        let totalScoreTime = (withScoreEvents.last!.date as! Date).timeIntervalSince(withScoreEvents.first!.date as! Date)
        
        if let episodeForScoreType = calculateScoreEpisodesOver5(events: withScoreEvents) {
            var timeOver5 = TimeInterval()
            for (start, end) in episodeForScoreType {
                timeOver5 += end.timeIntervalSince(start)
            }
            stats.moreThan5TimePct = 100 * timeOver5 / totalScoreTime
        }
        
        if let episodes = calculateScoreEpisodesUnder3(events: withScoreEvents) {
            var timeUnder3 = TimeInterval()
            for (start, end) in episodes {
                timeUnder3 += end.timeIntervalSince(start)
            }
            stats.lessThan3TimePct = 100 * timeUnder3 / totalScoreTime
        }

        stats.computed = true
        stats.numberOfScores  = withScoreEvents.count
        
        return stats
    }

    // MARK: - Episode stats
    
    func episodeStats() -> [EpisodeStats]? {
        
        let now = Date()
        
        var stats: [EpisodeStats]?
        let defaultStartDate = Date().addingTimeInterval(-24*3600)
        
        // 1. get startDate from earliest event (scoreEvent or medEvent) or regMed startDates
        let scoreEventsMinDate:Date = EventsDataController.sharedInstance().earliestScoreEventDate() ?? defaultStartDate
        
        // 2. get all medEvents and regMeds start- and endDates (if any or now) together ordered ascending
        var datesArray = [scoreEventsMinDate]
        
        if let medEvents = EventsDataController.sharedInstance().fetchAllMedEvents() {
            for event in medEvents {
                // print("event \(event.name), with date \(event.date)")
                datesArray.append(event.date as! Date)
                if (event.duration?.doubleValue ?? 0.0) > 0 {
                    datesArray.append(event.date!.addingTimeInterval(event.duration as! TimeInterval) as Date)
                }
            }
        }
        
        let regMedsFRC = MedicationController.sharedInstance().regMedsFRC
        if (regMedsFRC.fetchedObjects?.count ?? 0) > 0 {
            for regMed in regMedsFRC.fetchedObjects! {
                if !datesArray.contains(regMed.startDate as! Date) {
                    datesArray.append(regMed.startDate as! Date)
                }
                if regMed.endDate != nil {
                    if regMed.endDate!.compare(now) == .orderedAscending {
                        if !datesArray.contains(regMed.endDate as! Date) {
                            datesArray.append(regMed.endDate as! Date)
                        }
                    } else {
                        if !datesArray.contains(now) {
                            datesArray.append(now)
                        }
                    }
                }
            }
        }
        
        if datesArray.count > 0 {
            datesArray.sort(by: {$0.compare($1) == ComparisonResult.orderedAscending})
            stats = [EpisodeStats]()
        } else {
            // no events or regMeds present
            return stats
        }
        
        // 3. form episodes from these dates, with startDate and endDate back to back until nowDate
        var index = 0
        for aDate in datesArray {
            let newEpisode = EpisodeStats()
            newEpisode.startDate = aDate
            if index >= datesArray.count-1 {
                newEpisode.endDate = now
            } else {
                newEpisode.endDate = datesArray[index + 1]
            }
            stats!.append(newEpisode)
            index += 1
        }
        
        // 4. create EpisodeStats for each episode and calculate stats, which meds etc
        
        for episode in stats! {
            for type in RecordTypesController.sharedInstance().returnRecordTypesWithSavedEvents() {
                episode.scoreTypeName = type.name ?? ""
                let scoreEvents = EventsDataController.sharedInstance().fetchEventsBetweenDates(type: scoreEvent, name: type.name, startDate: episode.startDate, endDate: episode.endDate)
                calculateEpisodesStats(forStat: episode, withEvents: scoreEvents)
                
                if let regMedsTaken = MedicationController.sharedInstance().regMedsTakenDuringEpisode(start: episode.startDate, end: episode.endDate) {
                    for med in regMedsTaken {
                        episode.medNames.append(med.nameVar)
                    }
                    
                }
                
                
                if let prnMedsTaken = EventsDataController.sharedInstance().fetchMedEventsForEpisode(start: episode.startDate, end: episode.endDate) {
                    for med in prnMedsTaken {
                        episode.medNames.append(med.name ?? "")
                    }
                    
                }
            
            }
        }
        
        //* DEBUG
        
        if stats != nil {
            for stat in stats! {
                
                print()
                print("episodeStats from \(stat.startDate) to \(stat.endDate)")
                print(" - scoreType \(stat.scoreTypeName)")
                print(" - no. of scores \(stat.numberOfScores)")
                print(" - computed \(stat.computed)")
                print(" - meds taken \(stat.medNames)")
                print(" - min \(stat.min)")
                print(" - max \(stat.max)")
                print(" - mean \(stat.mean)")
                print(" - scores <3 \(stat.lessThan3Pct)%")
                print(" - time <3 \(stat.lessThan3TimePct)%")
                print(" - scores >5 \(stat.moreThan5Pct)%")
                print(" - time >5 \(stat.moreThan5TimePct)%")
            }
        }
 
        //*
        
        
        return stats
        
    }
    
    func calculateEpisodesStats(forStat: EpisodeStats, withEvents: [Event]?) {
        
        var scoreArray = [Double]()
        var over5Count: Double = 0
        var under3Count: Double = 0
        
        guard withEvents != nil else {
            forStat.computed = true
            return
        }
        guard withEvents!.count > 0 else {
            forStat.computed = true
            return
        }

        
        for event in withEvents! {
            scoreArray.append(event.vas as! Double)
            if event.vas!.doubleValue > 5.0 {
                over5Count += 1
            } else if event.vas!.doubleValue < 3.0 {
                under3Count += 1
            }
        }
        
        forStat.numberOfScores  = scoreArray.count
        forStat.max = scoreArray.max()!
        forStat.min = scoreArray.min()!
        forStat.mean = scoreArray.mean()
        forStat.computed = true
        
        if withEvents!.count > 1 {
        
            forStat.moreThan5Pct = 100.0 * over5Count / Double(scoreArray.count)
            forStat.lessThan3Pct = 100.0 * under3Count / Double(scoreArray.count)
            
            let totalScoreTypeTime = (withEvents!.last?.date as! Date).timeIntervalSince(withEvents!.first?.date as! Date)
            
            if let episodeForScoreType = calculateScoreEpisodesOver5(events: withEvents!) {
                var timeOver5 = TimeInterval()
                for (start, end) in episodeForScoreType {
                    timeOver5 += end.timeIntervalSince(start)
                }
                forStat.moreThan5TimePct = 100 * timeOver5 / totalScoreTypeTime
            }
            
            if let episodes = calculateScoreEpisodesUnder3(events: withEvents!) {
                var timeUnder3 = TimeInterval()
                for (start, end) in episodes {
                    timeUnder3 += end.timeIntervalSince(start)
                }
                forStat.lessThan3TimePct = 100 * timeUnder3 / totalScoreTypeTime
            }
        }
    }
    
}

let statisticsController = StatisticsController()
