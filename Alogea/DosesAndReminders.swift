//
//  DosesAndReminders.swift
//  Alogea
//
//  Created by mikeMBP on 21/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class DosesAndReminders: UITableViewController, UITextFieldDelegate {
    
    var drugData: DrugEpisode!
    //    var stack: CoreDataStack!
    var context: NSManagedObjectContext!
    var callingViewController: NewDrug!
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    
    let timesTag = 10
    //    let doseTag = 20
    let switchTag = 30
    let textFieldTag = 40
    let cellID = "doseDetailCell"
    
    var tempDoses:[Double]!
    var tempReminders:[Bool]!
    //    var textFieldOpen = [false, NSIndexPath(), UITextField()]
    var doseTextField: [UITextField]!
    var activeDoseTextField = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        //        context = stack.context
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(saveAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction))
        
        
        if tempDoses == nil {
            tempDoses = [Double]()
            for dose in drugData!.dosesVar
            {
                tempDoses.append(dose)
            }
        } else {
            tempDoses = drugData!.dosesVar
        }
        if tempReminders == nil {
            tempReminders = [Bool]()
            for reminder in drugData!.remindersVar {
                tempReminders.append(reminder)
            }
        } else {
            tempReminders = drugData!.remindersVar
        }
        
        doseTextField = [UITextField]()
        for _ in tempDoses {
            
            let newTextField = UITextField()
            newTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            doseTextField.append(UITextField())
        }
        
        
        
    }
    
    
    // MARK: - Custom functions
    
    func saveAction() {
        
        //        if textFieldOpen[0] == true {
        //            print("need to save open textField")
        //            textFieldShouldReturn(textFieldOpen[2] as! UITextField)
        //        }
        
        drugData!.dosesVar = tempDoses
        drugData.remindersVar = tempReminders
        
        let helper = callingViewController.cellRowHelper
        callingViewController.tableView.reloadRows(at: [helper!.returnPathForCellTypeInVisibleArray(cellType: "dosesCell")], with: .none)
        callingViewController.tableView.reloadRows(at: [helper!.returnPathForCellTypeInVisibleArray(cellType: "timesCell")], with: .none)
        
        self.navigationController!.popToViewController(callingViewController, animated: true)
        
    }
    
    func cancelAction() {
        self.navigationController!.popToViewController(callingViewController, animated: true)
    }
    
    func switchControlAction(sender: UISwitch ) {
        
        let allowedNotifications = (UIApplication.shared.delegate as! AppDelegate).authorisedNotificationSettings
        
        guard (UIApplication.shared.delegate as! AppDelegate).notificationsAuthorised else {
            showNotificationPermissionsAlert(message: "To receive medication reminders please allow Alogea to send you notifications in Settings > Notifications > Alogea. No reminder has been scheduled.")
            sender.isOn = false
            return
        }
        
        guard allowedNotifications?.alertStyle ==  UNAlertStyle.banner || allowedNotifications?.alertStyle ==  UNAlertStyle.alert else {
            showNotificationPermissionsAlert(message: "To see medicaton reminders please permit Alogea notifications to include sounds and alerts or at least banners. You can do this in Settings > Notifications > Alogea. No reminder has been scheduled.")
            sender.isOn = false
            return
        }
        
        //next check if the requried category exists
        guard (UIApplication.shared.delegate as! AppDelegate).reminderNotificationCategoryRegistered else {
            showNotificationPermissionsAlert(message: "Medication notification error: Reminder category not registered. Please inform our support team")
            sender.isOn = false
            return

        }
        
        let originatingCell: UITableViewCell = sender.superview?.superview as!UITableViewCell // first superview is contentView
        let indexPath = tableView.indexPath(for: originatingCell)
        
        if (indexPath?.row)! < drugData.remindersVar.count {
            tempReminders[(indexPath?.row)!] = sender.isOn
        }
        
        
        
    }
    
    func showNotificationPermissionsAlert(message:String?) {
        
        let alertMessage = message ?? "Notifcations are turned off. To enable reminders please turn on Notifications, in Settings > Notification > PDMF"

        let alertController = UIAlertController(title: title, message: alertMessage, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) -> Void in
            
        }))
        
        // Present Alert Controller
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func addDoneButtonToKeyboard (sender: UITextField) {
        
        let doneButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
        let space:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolbar = UIToolbar()
        toolbar.frame.size.height = 44
        doneButton.width = self.view.frame.width * 1/3
        //        toolbar.barTintColor = UIColor.grayColor()
        //        doneButton.customView = UIView() ->>> to imrpove doneButton appearance later
        
        var items = [UIBarButtonItem]()
        items.append(space)
        items.append(doneButton)
        
        toolbar.items = items
        
        sender.inputAccessoryView = toolbar
    }
    
    func doneButtonAction() {
        _ = textFieldShouldReturn(doseTextField[activeDoseTextField])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return drugData.dosesVar.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        var regSwitch: UISwitch!
        doseTextField[indexPath.row] = cell.contentView.viewWithTag(textFieldTag) as! UITextField
        
        if drugData.regularly == true {
            (cell.contentView.viewWithTag(timesTag) as! UILabel).text = drugData.times[indexPath.row]
            doseTextField[indexPath.row].delegate = self
            doseTextField[indexPath.row].keyboardType = .decimalPad
            addDoneButtonToKeyboard(sender: doseTextField[indexPath.row])
            doseTextField[indexPath.row].text = drugData.individualDoseString(index: indexPath.row)
        }
        else {
            doseTextField[indexPath.row].text = drugData.individualDoseString(index: indexPath.row)
            (cell.contentView.viewWithTag(timesTag) as! UILabel).text = "--:--"
        }
        
        
        if regSwitch == nil {
            regSwitch = (cell.contentView.viewWithTag(switchTag) as! UISwitch)
            regSwitch.isOn = drugData.remindersVar[indexPath.row]
            regSwitch.addTarget(self, action: #selector(switchControlAction(sender:)), for: UIControlEvents.valueChanged)
        }
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        activeDoseTextField = indexPath.row
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "dose details & reminders"
    }

    

    // MARK: - Navigation
 
    // MARK: - Text Field functions
    
    func  textFieldDidBeginEditing(_ textField: UITextField) {
        let originatingCell: UITableViewCell = textField.superview?.superview as! UITableViewCell // first superview is contentView
        let indexPath = tableView.indexPath(for: originatingCell)!
        activeDoseTextField = indexPath.row
        doseTextField[activeDoseTextField].placeholder = drugData.individualDoseString(index: indexPath.row, numberOnly: true)
        doseTextField[activeDoseTextField].text = ""
        
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        
        textField.sizeToFit()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        let originatingCell: UITableViewCell = textField.superview?.superview as! UITableViewCell // first superview is contentView
        let indexPath = tableView.indexPath(for: originatingCell)!
        
        if let entry = textField.text {
            if let doseFromString = numberFormatter.number(from: entry)?.doubleValue {
                tempDoses[indexPath.row] = doseFromString
            } else {
                tempDoses[indexPath.row] = 0.0
            }
            
        }
        
        let theDose = tempDoses[indexPath.row] as NSNumber
        doseTextField[indexPath.row] .text = numberFormatter.string(from: theDose)! + drugData.doseUnitVar!
        
        return false
    }
    
    
    
}
