//
//  MedsView.swift
//  Alogea
//
//  Created by mikeMBP on 27/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

let medBarHeight: CGFloat = 20.0 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
let eventDiamondSize: CGFloat = 22.0 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height

class MedsView: UIView {
    
    let cornerRadius: CGFloat = (8.0 / 1) * (medBarHeight / 14.0) * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width
    let fontSize: CGFloat = 12 * (medBarHeight / 14.0)
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()

    var graphView: GraphView!
    var helper: GraphViewHelper!
    var medController: MedicationController!
    
    var regMedsFRC: NSFetchedResultsController<DrugEpisode> = {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let regPredicate = NSPredicate(format: "regularly == true")
        
        request.predicate = regPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "regularly", ascending: false), NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedsVC Error 1", systemError: error)
        }
        return frc
    }()
    
    var currentRegMedsOnlyFRC: NSFetchedResultsController<DrugEpisode> = {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let regPredicate = NSPredicate(format: "regularly == true")
        let currentPredicate = NSPredicate(format: "isCurrent == %@", "Current Medicines")
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [regPredicate, currentPredicate])
        
        request.predicate = compoundPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "regularly", ascending: false), NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedsVC Error 1", systemError: error)
        }
        return frc
    }()

    
    var prnMedsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [medicineEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedsVC Error 2", systemError: error)
        }
        
        return frc
    }()
    
    var currentPrnMedOnlyFRC: NSFetchedResultsController<Event> = {
        // this should only apply if no med expansion purvhased so there is only one drug
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [medicineEvent])
        if let singleMedName = MedicationController.sharedInstance().returnSingleCurrentMedName() {
            let medNamePredicate = NSPredicate(format:"name == %@", singleMedName)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, medNamePredicate])
            request.predicate = compoundPredicate
        } else {
            request.predicate = predicate
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedsVC Error 2", systemError: error)
        }
        
        return frc
    }()

    
    var diaryEventsFRC: NSFetchedResultsController<Event> = {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [nonScoreEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            ErrorManager.sharedInstance().errorMessage(message: "MedsVC Error 3", systemError: error)
        }

        return frc
    }()
    
    var symbolArrays = [[CGRect]]()
    var regMedsDictionary = [(objectPath: IndexPath, eventRect: CGRect)]()
    var prnMedsDictionary = [(objectPath: IndexPath, eventRect: CGRect)]()
    var eventsDictionary = [(objectPath: IndexPath, eventRect: CGRect)]()
    var count = 0
    var colorArrayCount = 0
    let numberOfColors = ColorScheme.sharedInstance().barColors.count
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
    }
    
    convenience init(graphView: GraphView) {
        self.init()
        print("init MedsView)")

        self.graphView = graphView
        self.helper = graphView.helper
        self.frame = graphView.bounds
        self.backgroundColor = UIColor.clear
        self.alpha = 0

        
        self.medController = MedicationController.sharedInstance()
        
        regMedsFRC.delegate = self
        prnMedsFRC.delegate = self
        diaryEventsFRC.delegate = self
        print("finished init MedsView)")

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing methods
    
    override func draw(_ rect: CGRect) {
        
        print("draw MedsView)")
        if UserDefaults.standard.bool(forKey: "MedsViewEnabled") == false {
            return
        } else {
            alpha = 1.0
        }
        

        UIColor.white.setStroke()
        
        // symbol Arrays contains all med and eventRects for use in touch events
        symbolArrays.removeAll()
        regMedsDictionary.removeAll()
        prnMedsDictionary.removeAll()
        eventsDictionary.removeAll()

        let scale = graphView.maxDisplayDate.timeIntervalSince(graphView.minDisplayDate) / TimeInterval(graphView.frame.width)
        let vOffset = bounds.maxY - helper.timeLineSpace()
        
        drawRegularMeds(scale: scale, verticalOffset: vOffset)
        
        drawPrnMeds(scale: scale, verticalOffset: vOffset)
        
        drawNonScoreEvents(scale: scale, verticalOffset: vOffset)
        
        print("finished drawing MedsView)")
    }
    
    private func drawRegularMeds(scale: TimeInterval, verticalOffset: CGFloat) {
        
        var allRectsArray = [CGRect]()
        var topOfRect = verticalOffset
        count = 0
        colorArrayCount = 0
        var regMeds: NSFetchedResultsController<DrugEpisode>!
        
        if InAppStore.sharedInstance().checkDrugFormularyAccess() {
            regMeds = regMedsFRC
        } else {
            regMeds = currentRegMedsOnlyFRC
        }
        
        for medicine in regMeds.fetchedObjects! {
            var medRect = medicine.medRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medicine.startDateVar as Date, scale: scale), dy: verticalOffset)
            
            for i in 0..<count {
                if medRect.intersects(allRectsArray[i]) {
                    medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
//                    if medRect.minY < topOfRect {
//                        // ensure prnMedRect are positoned higher than regMedRects
//                        topOfRect = medRect.minY - medBarHeight - 2
//                    }
                }
            }
            let indexPath = IndexPath(item: count, section: 0)
            regMedsDictionary.append((indexPath, medRect))
            allRectsArray.append(medRect)
            
            let rightShift = 5 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
            let downShift = -1 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
            
            let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
            medRectPath.fill()
            medRectPath.stroke()
            let medName = medicine.nameVar as NSString?
            medName?.draw(in: medRect.offsetBy(dx: rightShift, dy: downShift), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
            count += 1
            colorArrayCount += 1
            if colorArrayCount == numberOfColors {
                colorArrayCount = 0
            }
        }
        symbolArrays.append(allRectsArray)
    }
    
    private func drawPrnMeds(scale: TimeInterval, verticalOffset: CGFloat) {
        
        var topOfRect = verticalOffset
        var allRectsArray = symbolArrays[0]
        var rectArray = [CGRect]()
        
        count = 0
        colorArrayCount = 0
        var sectionCount = 0
        // var eventCount = 0
        var intersectDetected = false
        
        var prnMeds: NSFetchedResultsController<Event>!
        
        if InAppStore.sharedInstance().checkDrugFormularyAccess() {
            prnMeds = prnMedsFRC
        } else {
            prnMeds = currentPrnMedOnlyFRC
        }

        
            for section in prnMeds.sections! {
                for index in 0..<section.numberOfObjects {
                    let medEvent = prnMedsFRC.object(at: IndexPath(item: index, section: sectionCount))
                    var medRect = medEvent.medEventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medEvent.date as! Date, scale: scale), dy: verticalOffset)
                    
                    repeat {
                        intersectDetected = false
                        for i in 0..<allRectsArray.count {
                            if medRect.intersects(allRectsArray[i]) {
                                medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                                intersectDetected = true
//                                if medRect.minY < topOfRect {
//                                    // ensure prnMedRect are positoned higher than regMedRects
//                                    topOfRect = medRect.minY - medBarHeight - 2
//                                }
                            }
                        }
                    } while intersectDetected
                    
                    let indexPath = IndexPath(item: index, section: sectionCount)
                    prnMedsDictionary.append((indexPath, medRect))
                    allRectsArray.append(medRect)
                    rectArray.append(medRect)
                    
                    let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
                    medRectPath.lineWidth = 1.0
                    ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
                    medRectPath.fill()
                    medRectPath.stroke()
                    
                    var medName = NSString()
                    if medRect.width == medBarHeight {
                        medName = (medEvent.name! as NSString).substring(to: 1) as NSString
                    } else {
                        medName = medEvent.name! as NSString
                    }
                    let rightShift = 3 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
                    let downShift = -1 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
                    
                    medName.draw(in: medRect.offsetBy(dx: rightShift, dy: downShift), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
                    
                    // eventCount += 1
                }
            colorArrayCount += 1
            if colorArrayCount == numberOfColors {
                colorArrayCount = 0
            }
            sectionCount += 1
        }
        symbolArrays.append(rectArray)
    }
    
    private func drawNonScoreEvents(scale: TimeInterval, verticalOffset: CGFloat)  {
        
        count = 0
        var allRectsArray: [CGRect] = Array(symbolArrays.joined())
        var rectArray = [CGRect]()
        
        var sectionCount = 0
        // var eventCount = 0
        var intersectDetected = false
        colorArrayCount = 0
        
        for section in diaryEventsFRC.sections! {
            for index in 0..<section.numberOfObjects {
                let event = diaryEventsFRC.object(at: IndexPath(item: index, section: sectionCount))
                var eventRect = event.nonScoreEventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: event.date as! Date, scale: scale), dy: verticalOffset)
                
                repeat {
                    intersectDetected = false
                    for i in 0..<allRectsArray.count {
                        if eventRect.intersects(allRectsArray[i]) {
                            eventRect = eventRect.offsetBy(dx: 0, dy: -eventDiamondSize - 2)
                            intersectDetected = true
                        }
                    }
                } while intersectDetected
                
                
                let indexPath = IndexPath(item: index, section: sectionCount)
                eventsDictionary.append((indexPath, eventRect))
                allRectsArray.append(eventRect)
                rectArray.append(eventRect)
                
                let diamondPath = UIBezierPath()
                diamondPath.move(to: CGPoint(x:eventRect.midX, y: eventRect.minY))
                diamondPath.addLine(to: CGPoint(x:eventRect.minX, y: eventRect.midY))
                diamondPath.addLine(to: CGPoint(x:eventRect.midX, y: eventRect.maxY))
                diamondPath.addLine(to: CGPoint(x:eventRect.maxX, y: eventRect.midY))
                diamondPath.addLine(to: CGPoint(x:eventRect.midX, y: eventRect.minY))
                
                diamondPath.lineWidth = 1.0
                ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
                diamondPath.fill()
                diamondPath.stroke()
                
                let rightShift = 4 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
                let downShift = 2 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
                
                let eventName = (event.name as NSString?)?.substring(to: 1)
                eventName?.draw(in: eventRect.offsetBy(dx: rightShift, dy: downShift), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize - 4)!,NSForegroundColorAttributeName: UIColor.white])
                
                // eventCount += 1
            }
            colorArrayCount += 1
            if colorArrayCount == numberOfColors {
                colorArrayCount = 0
            }
            sectionCount += 1
        }
        symbolArrays.append(rectArray)
    }
    
    private func leftXPosition(startDate: Date, scale: TimeInterval) -> CGFloat {
        
        return CGFloat(startDate.timeIntervalSince(graphView.minDisplayDate) / scale)
    }
    
    func tap(inLocation: CGPoint) {
        // tapGesture recogniser is property of GraphView
        
        var eventRect = CGRect()
        
        for (path,rect) in eventsDictionary {
            if rect.contains(inLocation) {
                let event = diaryEventsFRC.object(at: path)
                eventRect = rect
                graphView.mainViewController.eventTapPopUpView(eventObject: event, sourceRect: eventRect)
                return
            }
        }
        
        for (path,rect) in prnMedsDictionary {
            if rect.contains(inLocation) {
                let event = prnMedsFRC.object(at: path)
                eventRect = rect
                graphView.mainViewController.eventTapPopUpView(eventObject: event, sourceRect: eventRect)
                return
            }
        }

        for (path,rect) in regMedsDictionary {
            if rect.contains(inLocation) {
                let event = regMedsFRC.object(at: path)
                eventRect = rect
                graphView.mainViewController.eventTapPopUpView(eventObject: event, sourceRect: eventRect)
                return
            }
        }
    }
    
}

extension MedsView: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.setNeedsDisplay()
    }
    
}
