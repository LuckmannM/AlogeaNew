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
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    var eventObject: AnyObject!
    var theTitle: String!
    var theDate: String!
    var theNote: String!
    
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
            theTitle = event.name!
            theDate = dateFormatter.string(from: event.date as! Date)
            if event.note != nil {
                theNote = event.note!
            }
            
        } else {
            let medEvent = eventObject as! DrugEpisode
            theTitle = medEvent.name!
            theDate = dateFormatter.string(from: medEvent.startDate as! Date)
            theNote = medEvent.dosesString()
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
            self.managedObjectContext.delete(event)
        } else {
            let medEvent = eventObject as! DrugEpisode
            self.managedObjectContext.delete(medEvent)
        }
        
        do {
            try  managedObjectContext.save()
            print ("event deleted")
        }
        catch let error as NSError {
            print("Error saving in EventRect popover delate function \(error)", terminator: "")
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
