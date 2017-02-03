//
//  MedsView.swift
//  Alogea
//
//  Created by mikeMBP on 27/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

let medBarHeight: CGFloat = 12.0 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height
let eventDiamondSize: CGFloat = 15.0 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height

class MedsView: UIView {
    
    let cornerRadius: CGFloat = 8.0 / 2
    let fontSize: CGFloat = 11 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.height

    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()

    var graphView: GraphView!
    var helper: GraphViewHelper!
    var medController: MedicationController!
    
    var regMedsFRC: NSFetchedResultsController<DrugEpisode> {
        
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let regPredicate = NSPredicate(format: "regularly == true")
        
        request.predicate = regPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "regularly", ascending: false), NSSortDescriptor(key: "startDate", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("prnMedsFRC fetching error \(error)")
        }
        frc.delegate = self
        
        /* DEBUG
         for object in frc.fetchedObjects! {
         print("prn drug isCurrent is \(object.isCurrent)")
         print("prn drug endDate is \(object.endDate)")
         }
         */
        
        return frc
    }
    
    var prnMedsFRC: NSFetchedResultsController<Event> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [medicineEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("nonScoreEventTypesFRC fetching error \(error)")
        }
        frc.delegate = self
        
        return frc
    }
    
    var diaryEventsFRC: NSFetchedResultsController<Event> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        let predicate = NSPredicate(format: "type == %@", argumentArray: [nonScoreEvent])
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "date", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "name", cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let error as NSError{
            print("nonScoreEventsByDateFRC fetching error: \(error)")
        }
        frc.delegate = self
        return frc
    }
    
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
        print("init MedsView... ")

        self.graphView = graphView
        self.helper = graphView.helper
        self.frame = graphView.bounds
        self.backgroundColor = UIColor.clear
        
        self.medController = MedicationController.sharedInstance()
        
//        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(sender:)))
        
        print("...init MedsView end")

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing methods
    
    override func draw(_ rect: CGRect) {
        
        UIColor.white.setStroke()
        
        symbolArrays.removeAll()
        regMedsDictionary.removeAll()
        prnMedsDictionary.removeAll()
        eventsDictionary.removeAll()

        let scale = graphView.maxDisplayDate.timeIntervalSince(graphView.minDisplayDate) / TimeInterval(graphView.frame.width)
        
        drawRegularMeds(scale: scale, verticalOffset: bounds.maxY - helper.timeLineSpace())
        
        drawPrnMeds(scale: scale, verticalOffset: bounds.maxY - helper.timeLineSpace())
        
        drawNonScoreEvents(scale: scale, verticalOffset: bounds.maxY - helper.timeLineSpace())
        
        // symbol Arrays contains all med and eventRects for use in touch events
        
    }
    
    private func drawRegularMeds(scale: TimeInterval, verticalOffset: CGFloat) {
        
        var allRectsArray = [CGRect]()
        var topOfRect = verticalOffset
        count = 0
        colorArrayCount = 0
        for medicine in regMedsFRC.fetchedObjects! {
            var medRect = medicine.medRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medicine.startDate as! Date, scale: scale), dy: verticalOffset)
            
            for i in 0..<count {
                if medRect.intersects(allRectsArray[i]) {
                    medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                    if medRect.minY < topOfRect {
                        // ensure prnMedRect are positoned higher than regMedRects
                        topOfRect = medRect.minY - medBarHeight - 2
                    }
                }
            }
            let indexPath = IndexPath(item: count, section: 0)
            regMedsDictionary.append((indexPath, medRect))
            allRectsArray.append(medRect)
            
            
            let medRectPath = UIBezierPath(roundedRect: medRect, cornerRadius: cornerRadius)
            medRectPath.lineWidth = 1.0
            ColorScheme.sharedInstance().barColors[colorArrayCount].setFill()
            medRectPath.fill()
            medRectPath.stroke()
            let medName = medicine.name as NSString?
            medName?.draw(in: medRect.offsetBy(dx: 5, dy: -1), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
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
        var eventCount = 0
        
        for section in prnMedsFRC.sections! {
            for index in 0..<section.numberOfObjects {
                let medEvent = prnMedsFRC.object(at: IndexPath(item: index, section: sectionCount))
                var medRect = medEvent.medEventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: medEvent.date as! Date, scale: scale), dy: verticalOffset)
                
                for i in 0..<allRectsArray.count {
                    if medRect.intersects(allRectsArray[i]) {
                        medRect = medRect.offsetBy(dx: 0, dy: -medBarHeight - 2)
                        if medRect.minY < topOfRect {
                            // ensure prnMedRect are positoned higher than regMedRects
                            topOfRect = medRect.minY - medBarHeight - 2
                        }
                    }
                }
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
                medName.draw(in: medRect.offsetBy(dx: 3, dy: -1), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
                
                eventCount += 1
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
        var eventCount = 0
        colorArrayCount = 0
        
        for section in diaryEventsFRC.sections! {
            for index in 0..<section.numberOfObjects {
                let event = diaryEventsFRC.object(at: IndexPath(item: index, section: sectionCount))
                var eventRect = event.nonScoreEventRect(scale: scale).offsetBy(dx: leftXPosition(startDate: event.date as! Date, scale: scale), dy: verticalOffset)
                for i in 0..<allRectsArray.count {
                    if eventRect.intersects(allRectsArray[i]) {
                        eventRect = eventRect.offsetBy(dx: 0, dy: -eventDiamondSize - 2)
                    }
                }
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
                
                let eventName = (event.name as NSString?)?.substring(to: 1)
                eventName?.draw(in: eventRect.offsetBy(dx: 4, dy: 0), withAttributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: fontSize)!,NSForegroundColorAttributeName: UIColor.white])
                
                eventCount += 1
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
        
        var title = String()
        var date = Date()
        var text = String()
        var eventRect = CGRect()
        
        for (path,rect) in eventsDictionary {
            if rect.contains(inLocation) {
                let event = diaryEventsFRC.object(at: path)
                title = event.name!
                date = event.date as! Date
                text = event.note!
                eventRect = rect
                graphView.mainViewController.eventTapPopUpView(title: title, date: date, text: text, sourceRect: eventRect)
                return
            }
        }
        
        for (path,rect) in prnMedsDictionary {
            if rect.contains(inLocation) {
                let event = prnMedsFRC.object(at: path)
                title = event.name!
                date = event.date as! Date
                // text = event.name
                eventRect = rect
                graphView.mainViewController.eventTapPopUpView(title: title, date: date, text: text, sourceRect: eventRect)
                return
            }
        }

        for (path,rect) in regMedsDictionary {
            if rect.contains(inLocation) {
                let event = regMedsFRC.object(at: path)
                title = event.name!
                date = event.startDate as! Date
                text = event.dosesString()
                eventRect = rect
                graphView.mainViewController.eventTapPopUpView(title: title, date: date, text: text, sourceRect: eventRect)
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
