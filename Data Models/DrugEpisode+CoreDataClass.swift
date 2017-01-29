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
            if dosesVar == nil { return }
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
        startDate = calendar.date(from: newDateComponents) as NSDate?
        
        name = "name"
        isCurrent = "Current Medicines"
        classesVar = ["classes"]
        ingredientsVar = ["substances"]
        regularly = true
        frequency = 86400 // one day
        
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
    
    func copyFromDrug(drugToCopy: DrugEpisode) {
        self.name = drugToCopy.name
        self.startDate = drugToCopy.startDate
        self.endDate = drugToCopy.endDate
        self.ingredients = drugToCopy.ingredients
        self.classes = drugToCopy.classes
        self.doses = drugToCopy.doses
        self.regularly = drugToCopy.regularly
        self.reminders = drugToCopy.reminders
        self.frequency = drugToCopy.frequency
        self.doseUnit = drugToCopy.doseUnit
        self.effectiveness = drugToCopy.effectiveness
        self.sideEffects = drugToCopy.sideEffects
        self.notes = drugToCopy.notes
        self.attribute1 = drugToCopy.attribute1
        self.attribute2 = drugToCopy.attribute2
        self.attribute3 = drugToCopy.attribute3
        
        convertFromStorage()
        
    }
    
    func convertFromStorage() {
        
        nameVar = name
        if ingredients != nil {
            ingredientsVar = NSKeyedUnarchiver.unarchiveObject(with: ingredients as! Data) as? [String] ?? [String]()
        } else {
            ingredientsVar = [String]()
        }
        if classes != nil {
            classesVar = NSKeyedUnarchiver.unarchiveObject(with: classes! as Data) as? [String] ?? [String]()
        } else {
            classesVar = [String]()
        }
        
        startDateVar = startDate as Date!
        if endDate != nil {
            endDateVar = endDate as? Date
        }
        frequencyVar = frequency
        regularlyVar = regularly
        
        if doses != nil {
            dosesVar = NSKeyedUnarchiver.unarchiveObject(with: doses as! Data) as! [Double]
        } else {
            dosesVar = [0.0]
        }
        
        if reminders != nil {
            remindersVar = NSKeyedUnarchiver.unarchiveObject(with: reminders as! Data) as! [Bool]
        } else {
            remindersVar = [Bool]()
            for _ in dosesVar {
                remindersVar.append(false)
            }
        }
        
        doseUnitVar = doseUnit ?? "mg"
        notesVar = notes ?? String()
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
        if frequencyVar == 0 { frequencyVar = 24 * 3600 }
        if frequencyVar < 24*3600 {
            let dailyDoses = Int((24*3600)/frequencyVar)
            for i in 1..<dailyDoses {
                let dosingInterval_hours = frequencyVar * Double(i)
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
            dailyDoses = Int((24*3600)/frequencyVar)
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
    
    func resetReminders(default: [Bool] = [false]) {
        
        var i = 0
        remindersVar.removeAll()
        while i < numberOfDailyDoses() {
            remindersVar.append(Bool())
            i += 1
        }
    }


    
    // MARK: functions for DrugListViewController

    func returnName() -> String {
        
        guard  nameVar  != nil else { return name! }
        
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

    
    func storeObjectForEnding(endingDate: Date) {
        
        endDateVar = endingDate
        name = nameVar
        if ingredientsVar != nil {
            ingredients = NSKeyedArchiver.archivedData(withRootObject: ingredientsVar!) as NSData?
        }
        if classesVar != nil {
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
        cancelNotifications()
        
        do {
            try  self.managedObjectContext?.save()
            print("saving drug \(name) in DrugEpisode")
        }
        catch let error as NSError {
            print("Error saving \(error)", terminator: "")
        }

    }

    // MARK: - Notifications
    
    func cancelNotifications() {
        
       // let pendingNotifications = UIApplication.shared.scheduledLocalNotifications
        
        ((UIApplication.shared).delegate as! AppDelegate).removeSpecificNotifications(withIdentifier: drugID!, withCategory: notification_MedReminderCategory)
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
        
        guard (UIApplication.shared.delegate as! AppDelegate).notificationsAuthorised else {
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
//        print("...scheduling for \(nameVar); has \(remindersVar) remindersVar")
        for aReminder in remindersVar {
            if aReminder {
                // creating a notification via request
                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: "Medication reminder", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "it's time to take %@", arguments: [messageForDrugAlert(index: i)])
                content.categoryIdentifier = notification_MedReminderCategory
                content.sound = UNNotificationSound.default()
                    
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
                    print("scheduled notification \(request.identifier) with date \(reminderDate)")
                    print("content body is \(content.body)")

                })
            }
            i = i+1
        }
        
    }
    
    func messageForDrugAlert(index: Int) -> String {
        
            return returnName() + " " + individualDoseString(index: index)

    }
    
    func individualDoseString(index: Int, numberOnly: Bool = false) -> String {

        if numberOnly {
            if index <= dosesVar.count {
                return numberFormatter.string(from: NSNumber(value:dosesVar[index]))!
            } else {
                return numberFormatter.string(from: NSNumber(value:dosesVar[0]))!
            }
        } else {
            if index <= dosesVar.count {
                return (numberFormatter.string(from: NSNumber(value:dosesVar[index]))! + " " + doseUnitVar)
            } else {
                return (numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + " " + doseUnitVar)
            }
        }
    }

    // MARK:- NewDrug helper methods
    
    func storeObjectAndNotifications() {
        
        //createNotificationsWithoutActions()
        
        scheduleReminderNotifications()
        
        name = nameVar
        if ingredients != nil {
            ingredients = NSKeyedArchiver.archivedData(withRootObject: ingredientsVar!) as NSData!
        }
        if classes != nil {
            classes = NSKeyedArchiver.archivedData(withRootObject: classesVar!) as NSData!
        }
        startDate = startDateVar as NSDate!
        endDate = endDateVar as NSDate!
        frequency = frequencyVar
        regularly = regularlyVar
        doses = NSKeyedArchiver.archivedData(withRootObject: dosesVar) as NSData!
        reminders = NSKeyedArchiver.archivedData(withRootObject: remindersVar) as NSData!
        doseUnit = doseUnitVar
        notes = notesVar
        sideEffects = NSKeyedArchiver.archivedData(withRootObject: sideEffectsVar!) as NSData!
        isCurrent = "Current Medicines"
        isCurrentUpdate()
    }

    func timesString() -> String {
        
        if regularlyVar == false {
            return "\(frequencyString())"
        }
        
        calculateDoseTimes()
        
        var times$ = String()
        var i = 0
        for aTime in times {
            if remindersVar[i] { times$ += "  🔔" + aTime }
            else { times$ += "  " + aTime }
            i += 1
        }
        
        return times$
    }

    func dosesString() -> String {
        
        var doses$ = String()
        
        if regularlyVar == true {
            let minimum = dosesVar.min()
            let maximum = dosesVar.max()
            
            if maximum! > 1.0 && doseUnitVar.contains("tablet") {
                doseUnitVar = "tablets"
            }
            
            if minimum == maximum {
                doses$ = frequencyString() + "  " + numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + " " + doseUnitVar
            } else {
                doses$ = frequencyString() + ", " + numberFormatter.string(from: NSNumber( value: minimum!))! + "-" + numberFormatter.string(from: NSNumber( value: maximum!))! + " " + doseUnitVar
            }
        } else { // as required drugs only have one dose
            doses$ = "  " + numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + " " + doseUnitVar
        }
        
        return doses$
    }
    func dosesShortString() -> String {
        
        var doses$ = String()
        
        if regularlyVar == true {
            let minimum = dosesVar.min()
            let maximum = dosesVar.max()
            
            if maximum! > 1.0 && doseUnitVar.contains("tablet") {
                doseUnitVar = "tablets"
            }
            
            if minimum == maximum {
                doses$ = numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + " " + doseUnitVar
            } else {
                doses$ = numberFormatter.string(from: NSNumber( value: minimum!))! + "-" + numberFormatter.string(from: NSNumber( value: maximum!))! + " " + doseUnitVar
            }
        } else { // as required drugs only have one dose
            doses$ = "  " + numberFormatter.string(from: NSNumber(value:dosesVar[0]))! + " " + doseUnitVar
        }
        
        return doses$
    }


    func startDateString() -> String {
        return dateFormatter.string(from: startDateVar)
    }
    
    func trialPeriodToEndDate(trialPeriodNo: Int, trialPeriodMetric: String) -> String {
        
        var trialPeriod: TimeInterval
        
        switch trialPeriodMetric {
        case "days":
            trialPeriod = 24.0 * 3600.0
        case "weeks":
            trialPeriod = 7.0 * 24.0 * 3600.0
        case "months":
            trialPeriod = 30.0 * 24.0 * 3600.0
        default:
            trialPeriod = -24.0 * 3600.0
        }
        
        let timeInterval: TimeInterval = Double(trialPeriodNo) * trialPeriod
        endDateVar = startDateVar.addingTimeInterval(timeInterval)
        
        return endDateString()
        
    }
    
    func frequencyStringToTimeInterval(term: String) {
        
        for aTerm in frequencyTerms {
            let (presetTerm,duration) = aTerm
            if term == presetTerm {
                frequencyVar = duration
                return
            }
        }
    }
    
    func frequencyToPickerViewRow() -> Int {
        
        var pickerRow = 5
        
        var i = 0
        for aTerm in frequencyTerms {
            let (_,duration) = aTerm
            if frequencyVar == duration {
                pickerRow = i
            }
            i += 1
        }
        
        return pickerRow
        
    }
    
    func doseUnitIndex() -> Int {
        switch doseUnitVar {
        case "mg":
            return 0
        case "grams":
            return 1
        case "µg/h":
            return 2
        case "tablet":
            return 3
        case "tablets":
            return 3
        default:
            return 0
        }
    }
    
    func saveDoseUnit(index: Int) {
        
        switch index {
        case 0:
            doseUnitVar = "mg"
        case 1:
            doseUnitVar = "grams"
        case 2:
            doseUnitVar = "µg/h"
        case 3:
            if dosesVar[0] > 1.0 {
                doseUnitVar = "tablets"
            } else {
                doseUnitVar = "tablet"
            }
        default:
            doseUnitVar = "error"
        }
        
    }

//    func getDetailsFromCloudDrug(publicDrug: CloudDrug) {
//        
//        name = publicDrug.displayName
//        if publicDrug.substances != nil {
//            ingredientsVar = publicDrug.substances
//        }
//        if publicDrug.classes != nil {
//            classesVar = publicDrug.classes
//        }
//        if publicDrug.doseUnit != nil {
//            doseUnitVar = publicDrug.doseUnit
//            
//        }
//        if publicDrug.startingDoses != nil {
//            dosesVar = publicDrug.startingDoses
//        }
//        if publicDrug.regular != nil {
//            if publicDrug.regular == 1 { regularlyVar = true }
//            else {regularlyVar = false }
//        }
//        if publicDrug.startingDoseInterval != nil {
//            frequency = publicDrug.startingDoseInterval as TimeInterval
//        }
//        
//        resetReminders()
//        
//        // *** also transfer other parameter here...
//    }

    
    // MARK: - DrugRating helper methods
    
    func saveEffectAndSideEffects() {
        effectiveness = effectivenessVar
        sideEffects = NSKeyedArchiver.archivedData(withRootObject: sideEffectsVar ?? [""]) as NSData?
    }

    // MARK: - SubstanceAndClassPopUp methods
    
    func substancesString() -> String {
        
        if ingredientsVar?.count == 0 {
            return "unkown"
        } else if ingredientsVar?[0] == "ingredients" || ingredientsVar?[0] == "substances" {
            return "unkown"
        }
        
        var ingredient$ = String()
        for aString in ingredientsVar! {
            ingredient$ += aString + ", "
        }
        return (ingredient$ as NSString).substring(to: (ingredient$ as NSString).length - 2)
    }
    
    func classesString() -> String {
        
        if (classesVar?.count)! == 0 {
            return "unknown"
        } else if classesVar?[0] == "classes" {
            return "unkown"
        }
        
        var class$ = String()
        for aString in classesVar! {
            class$ += aString + ", "
        }
        return (class$ as NSString).substring(to: (class$ as NSString).length - 2)
    }

    // NewDrug TVC methods
    
    func getDetailsFromPublicDrug(publicDrug: CloudDrug, nameChosen: String? = nil) {
        
        if nameChosen != nil {
            nameVar = nameChosen
        }
        if publicDrug.substances != nil {
            ingredientsVar = publicDrug.substances
        }
        if publicDrug.classes != nil {
            classesVar = publicDrug.classes
        }
        
        
        // link between doseUnit and doses: id multiple substances/ingredients, each withn it's own dose exist then switch the shown doseUnit from e.g. mg in cloudDrug to 'tablets' in this database to keep things simple. If not doseUnit is present (which shouldn't happen) use the cloudDrug's startingDoses to avoid empty variables
        if publicDrug.doseUnit != nil {
            if ingredientsVar != nil {
                if ingredientsVar!.count > 1 {
                    dosesVar[0] = publicDrug.startingDoses[0] / publicDrug.singleUnitDoses[0]
                    if dosesVar[0] > 1 {
                        doseUnitVar = "tablets"
                    } else {
                        doseUnitVar = "tablet"
                    }
                } else {
                    doseUnitVar = publicDrug.doseUnit
                    if publicDrug.startingDoses != nil {
                        dosesVar = publicDrug.startingDoses
                    }
                }
            } else {
                doseUnit = publicDrug.doseUnit
                if publicDrug.startingDoses != nil {
                    dosesVar = publicDrug.startingDoses
                }
            }
        } else {
            if publicDrug.startingDoses != nil {
                dosesVar = publicDrug.startingDoses
            }
        }
        
        // *** this needs more consideration, particularly if the are multiple substances and doses. In this case it may be better to use 'tablets' instead of mg/g etc!

        
        if publicDrug.regular != nil {
            if publicDrug.regular == 1 { regularlyVar = true }
            else {regularlyVar = false }
        }
        if publicDrug.startingDoseInterval != nil {
            frequencyVar = publicDrug.startingDoseInterval as TimeInterval
        }
        
        resetReminders()
        
        // *** also transfer other parameter here...
    }

    // MARK: - MedsView functions
    
    func graphicalDuration(scale: TimeInterval) -> CGFloat {
        
        let endingDate = endDate ?? NSDate() // endDateVar is nil after fetching
        let timeDuration = endingDate.timeIntervalSince(startDate as! Date)
       
        return CGFloat(timeDuration / scale)
    }
    
    func medRect(scale: TimeInterval) -> CGRect {
        
        let endingDate = endDate ?? NSDate() // endDateVar is nil after fetching
        let timeDuration = endingDate.timeIntervalSince(startDate as! Date)
        
        let rect = CGRect(x: 0, y: -15, width: CGFloat(timeDuration / scale), height: medBarHeight)
        
        return rect
    }



}
