//
//  EventRect PopUp.swift
//  Alogea
//
//  Created by mikeMBP on 03/02/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

class EventPopUp: UIViewController {

 
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    var eventObject: AnyObject!
    var theTitle: String!
    var theDate: String!
    var theNote: String!
    
    var graphContainer: GraphContainerView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func labelTexts(eventObject: AnyObject) {
        
        self.eventObject = eventObject
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        theNote = "" // if prnMedEvent event.note maybe nil
        
        if let event = eventObject as? Event {
            deleteButton.isHidden = false
            deleteButton.isEnabled = true
            
            theTitle = event.name!
            theDate = dateFormatter.string(from: event.date as! Date)
            if event.note != nil {
                theNote = event.note!
            }
            
        } else {
            // regular meds should be deleted on DrugLists VC only
            
            let medEvent = eventObject as! DrugEpisode
            theTitle = medEvent.name!
            theDate = dateFormatter.string(from: medEvent.startDate as! Date)
            theNote = medEvent.dosesString() + "\n" + (medEvent.notes ?? "")
        }
        
        titleLabel.text = theTitle
        titleLabel.sizeToFit()
        titleLabel.isHidden = false
        
        dateLabel.text = theDate
        dateLabel.sizeToFit()
        dateLabel.isHidden = false
        
        textView.text = theNote
        textView.isHidden = false
    }
    
    
    @IBAction func deleteEvent(_ sender: UIButton) {
        
        if let event = eventObject as? Event {
            deleteAlert(object: event)
        }
        
        
    }
    
    func deleteAlert(object: Event) {
        
        let deleteAlert = UIAlertController(title: "Delete event?", message: nil, preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: { (deleteAlert)
            -> Void in
            
            self.managedObjectContext.delete(object)
            do {
                try  self.managedObjectContext.save()
            }
            catch let error as NSError {
                ErrorManager.sharedInstance().errorMessage(message: "EventRectPopUpVC Error 1", systemError: error, errorInfo:"Error saving in EventRect popover delate function")
            }

            self.dismiss(animated: true, completion: { (void) in
                
                self.graphContainer.graphView.medsView.setNeedsDisplay()
                
            })

        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (deleteAlert)
            -> Void in
            
            self.dismiss(animated: true, completion: { (void) in
                
                self.graphContainer.graphView.medsView.setNeedsDisplay()
                
            })
        })
        
        deleteAlert.addAction(proceedAction)
        deleteAlert.addAction(cancelAction)
        
        // iPads have different requirements for AlertControllers!
        if UIDevice().userInterfaceIdiom == .pad {

            let popUpController = deleteAlert.popoverPresentationController
            popUpController!.permittedArrowDirections = .any
            popUpController!.sourceView = self.deleteButton
            popUpController!.sourceRect = self.deleteButton.bounds
        }
        
        self.present(deleteAlert, animated: true, completion: nil)
        
    }

}
