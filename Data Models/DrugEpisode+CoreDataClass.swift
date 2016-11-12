//
//  DrugEpisode+CoreDataClass.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

// import Foundation
import UIKit
import CoreData
import UserNotifications


public class DrugEpisode: NSManagedObject {
    
    var nameVar: String!
    var ingredientsVar: [String]?
    var classesVar: [String]?
    var startDateVar: Date!
    var endDateVar: Date?
    var dosesVar:[Double]!
    var doseUnitVar: String!
    var regularlyVar: Bool!
    var effectivenessVar: String?
    var sideEffectsVar: [String]?
    var notesVar: String?
    var remindersVar: [Bool]!
    var frequencyVar: TimeInterval = 24*3600 {
        didSet {
            calculateDoseTimes()                    // sets [doseTimeDates]
            if doses == nil { return }
            if dosesVar.count != numberOfDailyDoses() {
                setDoseArray(sentDose: dosesVar[0])
            }
        }
    }

    var needsUpdate = false
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = "dd.MM.yyyy" // time/date symbols shown on the bottom timeLine
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    let frequencyTerms:[(String, Double)] = [("hourly",3600.0),("every 4 hours",4*3600.0),("4x per day",6*3600.0),("3x per day",8*3600.0),("twice daily",12*3600.0),("once daily",24*3600.0),("every other day",48*3600.0),("every three days",72*3600.0),("once weekly",7*24*3600.0)]
    
    var times = [""]
    var doseTimeDates = [Date]() {
        didSet {
            doseTimeDates.sort(by: {$0.compare($1) == ComparisonResult.orderedAscending})
            times.removeAll()
            for date in doseTimeDates {
                times.append(timeFormatter.string(from: date))
            }
        }
    }


    override public func awakeFromInsert()
    {
        super.awakeFromInsert()
        
        let calendar = NSCalendar.current
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = "dd.MM.yy - HH:mm:ss"
        drugID = formatter.string(from: Date())
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        var newDateComponents = calendar.dateComponents(components, from: Date())
        
        newDateComponents.second = 0
        newDateComponents.minute = Int(round(Double(newDateComponents.minute!) / 5.0) * 5.0)
        startDateVar = calendar.date(from: newDateComponents)
        
        nameVar = "name"
        classesVar = ["classes"]
        ingredientsVar = ["substances"]
        regularlyVar = true
        frequencyVar = 86400 // one day
        
        convertFromStorage()
    }
    
    override public func awakeFromFetch()
    {
        // the method will be called only once after fetch
        // if the app keeps running it will not be called again if/when fetched again
        super.awakeFromFetch()
        
        isCurrentUpdate()
        convertFromStorage()
    }
    
    func convertFromStorage() {
        
        nameVar = name
        if ingredients != nil {
            ingredientsVar = NSKeyedUnarchiver.unarchiveObject(with: ingredients! as Data) as? [String]
        } else {
            ingredientsVar = [String]()
        }
        
        if classes != nil {
            classesVar = NSKeyedUnarchiver.unarchiveObject(with: classes! as Data) as? [String]
        } else {
            classesVar = [String]()
        }
        
        startDateVar = startDate as Date!
        if endDate != nil {
            endDateVar = endDate! as Date
        }
        
        frequencyVar = frequency
        
        regularlyVar = regularly
        
        if let _ = NSKeyedUnarchiver.unarchiveObject(with: doses as! Data) {
            dosesVar = NSKeyedUnarchiver.unarchiveObject(with: doses as! Data) as! [Double]
        } else {
            dosesVar = [0.0]
        }
        
        if let _ = NSKeyedUnarchiver.unarchiveObject(with: reminders as! Data) {
            remindersVar = NSKeyedUnarchiver.unarchiveObject(with: reminders as! Data) as! [Bool]
        } else {
            remindersVar = [Bool]()
            for _ in dosesVar {
                remindersVar.append(false)
            }
        }
        
        doseUnitVar = doseUnit
        
        if let text = notes {
            notesVar = text
        } else {
            notesVar = String()
        }
        
        effectivenessVar = effectiveness
        if sideEffects != nil {
            sideEffectsVar = NSKeyedUnarchiver.unarchiveObject(with: sideEffects! as Data) as? [String]
        } else {
            sideEffectsVar = [String]()
        }
        
        
        calculateDoseTimes()
    }

    // MARK: custom functions
    
    func isCurrentUpdate() {
        
        let preUpdateState = isCurrent
        let now = Date()
        
        if endDate != nil {
            if endDate!.compare(now) == .orderedAscending {
                isCurrent = "Discontinued Medicines"
            }
        }
        
        if preUpdateState != isCurrent { needsUpdate = true }
        else { needsUpdate = false }
    }
    
    func calculateDoseTimes() {
        
        times = [timeFormatter.string(from: startDateVar)]
        doseTimeDates = [startDateVar]
        
        let calendar = NSCalendar.current
        if frequency == 0 { frequency = 24 * 3600 }
        if frequency < 24*3600 {
            let dailyDoses = Int((24*3600)/frequency)
            for i in 1..<dailyDoses {
                let dosingInterval_hours = frequency * Double(i)
                let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
                var newDateComponents = calendar.dateComponents(components, from: startDateVar.addingTimeInterval(dosingInterval_hours))
                newDateComponents.second = 0
                let timeOnly = calendar.date(from: newDateComponents)
                doseTimeDates.append(timeOnly!)
            }
        }
    }

    func numberOfDailyDoses() -> Int {
        
        var dailyDoses = 1
        if frequencyVar == 0 { frequencyVar = 24 * 3600 }
        if frequencyVar < 24*3600 {
            dailyDoses = Int((24*3600)/frequency)
        }
        return dailyDoses
    }

    func setDoseArray(sentDose:Double) {
        
        dosesVar[0] = sentDose
        if numberOfDailyDoses() > dosesVar.count {
            for _ in dosesVar.count..<numberOfDailyDoses() {
                dosesVar.append(sentDose)
                remindersVar.append(false)
            }
            
        } else if numberOfDailyDoses() < dosesVar.count {
            let newDoses = dosesVar.dropLast((dosesVar.count - numberOfDailyDoses()))
            let newReminders = remindersVar.dropLast((dosesVar.count - numberOfDailyDoses()))
            dosesVar.removeAll()
            remindersVar.removeAll()
            for dose in newDoses {
                dosesVar.append(dose)
            }
            for reminder in newReminders {
                remindersVar.append(reminder)
            }
        }
        
    }
    func frequencyString() -> String {
        
        var freqString = String()
        
        if regularlyVar == false {
            freqString = "as required, "
        }
        
        for aTerm in frequencyTerms {
            let (term, duration) = aTerm
            if frequencyVar == duration {
                freqString += term
            }
        }
        
        return freqString
    }

    
    // MARK: functions for DrugListViewController

    func returnName() -> String {
        
        guard  nameVar  != nil else { return nameVar }
        
        if nameVar == "name" && name != "name" {
            return nameVar
        } else if nameVar == "" { return nameVar }
        else { return nameVar }
    }

    func returnTimeOnDrug () -> String {
        
        var timeInterval: TimeInterval
        
        if endDateVar != nil {
            if Date().compare(endDateVar!) == .orderedAscending {
                timeInterval = Date().timeIntervalSince(startDate as! Date)
            } else {
                timeInterval = endDateVar!.timeIntervalSince(startDate as! Date)
            }
        } else {
            timeInterval = Date().timeIntervalSince(startDate as! Date)
        }
        
        let componentFormatter = DateComponentsFormatter()
        componentFormatter.unitsStyle = .full
        componentFormatter.zeroFormattingBehavior = .dropAll
        componentFormatter.maximumUnitCount = 1
        componentFormatter.includesApproximationPhrase = false
        
        return componentFormatter.string(from: timeInterval)!
    }
    
    func endDateString() -> String {
        
        if endDateVar == nil { return "" }
        else { return dateFormatter.string(from: endDateVar!) }
    }
    
    func returnEffect() -> String {
        
        if let effect = effectivenessVar {
            return effect
        } else {
            return "in evaluation"
        }
    }

    func returnSideEffect() -> String {
        
        if (sideEffectsVar?.count)! > 0 {
            return sideEffectsVar![0]
        } else {
            return "in evaluation"
        }
    }
    

    func dosesAndFrequencyForPrint() -> String {
        var doses$ = String()
        
        if regularlyVar == true {
            let minimum = dosesVar.min()
            let maximum = dosesVar.max()

            if minimum == maximum {
                doses$ = numberFormatter.string(from: NSNumber(value: minimum!))! + doseUnitVar + ", " + frequencyString()
            } else {
                doses$ = numberFormatter.string(from: NSNumber(value: minimum!))! + "-" + numberFormatter.string(from : NSNumber(value: maximum!))! + doseUnitVar + ", " + frequencyString()
            }
        } else { // as required drugs only have one dose
            doses$ = "  " + numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + doseUnitVar + ", " + frequencyString()
        }
        
        return doses$
    }

    func setTheEndDate(date: Date) {
        endDateVar = date
        isCurrentUpdate()
        
    }
    
    func storeObjectForEnding() {
        
        name = nameVar
        if ingredientsVar != nil {
            ingredients = NSKeyedArchiver.archivedData(withRootObject: ingredientsVar!) as NSData?
        }
        if classes != nil {
            classes = NSKeyedArchiver.archivedData(withRootObject: classesVar!) as NSData?
        }
        startDate = startDateVar as NSDate?
        endDate = endDateVar as NSDate?
        frequency = frequencyVar
        regularly = regularlyVar
        doses = NSKeyedArchiver.archivedData(withRootObject: dosesVar) as NSData?
        reminders = NSKeyedArchiver.archivedData(withRootObject: remindersVar) as NSData?
        doseUnit = doseUnitVar
        notes = notesVar
        sideEffects = NSKeyedArchiver.archivedData(withRootObject: sideEffectsVar!) as NSData?
        isCurrent = "Discontinued Medicines"
        isCurrentUpdate()
        
    }

    // MARK: - Notifications
    
    func cancelNotifications() {
        
       // let pendingNotifications = UIApplication.shared.scheduledLocalNotifications
        
        ((UIApplication.shared).delegate as! AppDelegate).removeNotifications(withIdentifier: drugID!, withCategory: "drugReminderCategory")
    }
    
    func nextDoseDueDates() -> [Date] {
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        let calendar = NSCalendar.current
        var dueDates = [Date]()
        var nextDueDate: Date!
        
        for date in doseTimeDates {
            var nextDueComponents = calendar.dateComponents(components, from: date)
            if date.compare(Date()) == .orderedAscending { // nextDueDate is before now
                
                if frequencyVar <= 24 * 3600 {
                    nextDueComponents.day = nextDueComponents.day! + 1
                    nextDueDate = calendar.date(from: nextDueComponents)
                    dueDates.append(nextDueDate)
                } else { // dose frequency is > 1 day
                    nextDueComponents.day = nextDueComponents.day! + Int(frequencyVar / (24 *  3600))
                    nextDueComponents.hour = nextDueComponents.hour! + Int(frequencyVar.truncatingRemainder(dividingBy: 24*3600) / 3600)
                    nextDueDate = calendar.date(from: nextDueComponents)
                    dueDates.append(nextDueDate!)
                }
                
            } else { //  nextDueDate is later than now
                dueDates.append(date)
            }
        }
        return dueDates
    }
    
    func scheduleReminderNotifications(cancelExisting: Bool = false) {
        
        if cancelExisting { cancelNotifications() }
        
        guard notificationsAuthorised else {
            return
        }
        
        guard regularlyVar! else {
            return
        }
        let center = UNUserNotificationCenter.current()
        let calendar = NSCalendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        let nextDoseDueDates = self.nextDoseDueDates()
        
        var i = 0
        // each dose has it's own reminder
        for _ in remindersVar {
            
            // creating a notification via request
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: "Medication reminder", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: "time to take @%", arguments: [returnName(), individualDoseString(index: i)])
            content.categoryIdentifier = "drugReminderCategory"
            content.sound = UNNotificationSound.default()
            
            /*
            let reminderDate: DateComponents = {
                
                var alertDate = DateComponents()
                if frequencyVar <= 24 * 3600 {
                    // var nowDate = calendar.dateComponents(components, from: Date())
                    let doseAlert = calendar.dateComponents(components, from: self.doseTimeDates[i])
                    
                    // this sets alert for defined time every day
                    alertDate.hour = doseAlert.hour
                    alertDate.minute = doseAlert.minute
                } else {
                    let components: Set<Calendar.Component> = [.day, .hour, .minute]
                    let doseAlert = calendar.dateComponents(components, from: self.doseTimeDates[i])
                    
                    alertDate.day = doseAlert.day
                    alertDate.hour = doseAlert.hour
                    alertDate.minute = doseAlert.minute
                }
                // special cases: drugs not due every day but every other, third day or once weekly!
                return alertDate

            }()
             */
            
            let reminderDate = calendar.dateComponents(components, from: nextDoseDueDates[i])
            
            let alertTrigger = UNCalendarNotificationTrigger(dateMatching: reminderDate, repeats: true)
            // another trigger using timerIntervals
            // let alert2Trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            
            let request = UNNotificationRequest(identifier: drugID!, content: content, trigger: alertTrigger)
            
            // scheduling a notification
            center.add(request, withCompletionHandler: {
                (error: Error?) in
                if let theError = error {
                    print("error in scheduling \(request.identifier) is \(theError.localizedDescription)")
                }
            })

            i = i+1
        }
        
    }
    
    func individualDoseString(index: Int, numberOnly: Bool = false) -> String {
        
        if numberOnly {
            return numberFormatter.string(from: NSNumber(value:dosesVar[0]))!
        } else {
            return (numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + doseUnitVar)
        }
    }



}
