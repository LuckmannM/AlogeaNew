//
//  NewDrug.swift
//  Alogea
//
//  Created by mikeMBP on 12/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import CloudKit

typealias TrialDuration = (number:Int, metric: String)

class NewDrug: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    var rootViewController: DrugListViewController!
    
    var drugFromList: DrugEpisode?
    lazy var theNewDrug: DrugEpisode? =
        {
            if self.drugFromList != nil {
                return self.drugFromList!
            } else {
                return NSEntityDescription.insertNewObject(forEntityName: "DrugEpisode", into: self.managedObjectContext) as? DrugEpisode
            }
    }()
    

    var drugDictionary: DrugDictionary!
    var inAppStore: InAppStore!

    
    var cellRowHelper: NewDrugHelper!
    
    var dropDownButton: UIButton!
    
    var datePicker: UIDatePicker!
    var timesPicker: UIDatePicker!
    var trialDurationPicker: UIPickerView!
    var frequencyPicker: UIPickerView!
    var drugNamePicker: UIPickerView!
    var regularitySwitch: UISwitch!
    var doseUnitSelection: UISegmentedControl!
    var notesTextView: UITextView!
    
    var trialDurationPickerValues:[[String]]!
    var frequencyPickerValues: [String]!
    var drugNamePickerValues: [String]!
    var drugNamePickerIndexReferences: [Int]!
    
    var trialDurationChosen: TrialDuration!
    var frequencyChosen: String!
    var drugIndexChosen: Int!
    var numberFormatter: NumberFormatter!
    var isDiscontinuedDrug: Bool!
    var initialTouchLocation: CGPoint = CGPoint.zero
    var doseDetailLabel: UILabel!
    
    let titleTag = 10
    let detailTag = 20
    let controlTag = 30
    let textViewTag = 40
    //    let textFieldTag = 50
    
    typealias openTextFieldInfo = (isOpen: Bool, path: IndexPath, text: String, textField: UITextField)
    var textFieldOpen: openTextFieldInfo = (false, IndexPath(),"", UITextField())
    
    // MARK: - TVC functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(saveAction))
        
        let cloudButton = UIButton(type: .custom)
        
        if drugDictionary.iCloudStatus == CKAccountStatus.available && InAppStore.sharedInstance().isConnectedToNetwork() {
            cloudButton.setImage(UIImage(named: "BlueCloud"), for: .disabled)
        } else {
            cloudButton.setImage(UIImage(named: "GreyCloud"), for: .disabled)
        }
        cloudButton.frame = CGRect(x: 0, y: 0, width: (75*20/50), height: 20)
        let cloudIcon = UIBarButtonItem(customView: cloudButton)
        cloudIcon.isEnabled = false
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = self.view.frame.width / 2 - cloudButton.frame.width / 2 - 50
        
        
        isDiscontinuedDrug = false
        if let theEnd = theNewDrug!.endDate {
            let now = Date()
            if theEnd.compare(now) == .orderedAscending { // is old drug - not modifiable
                isDiscontinuedDrug = true
                
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(cancelAction))
            } else {
                self.navigationItem.setRightBarButtonItems([saveButton, cloudIcon], animated: true)
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction))
            }
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction))
            self.navigationItem.setRightBarButtonItems([saveButton, spacer, cloudIcon], animated: true)
        }
        
        cellRowHelper = NewDrugHelper()
        cellRowHelper.initHelper(regularly: theNewDrug!.regularly)
        
        inAppStore  = InAppStore.sharedInstance()
        initiateClassObjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        let bar = self.tabBarController!.tabBar
        self.hidesBottomBarWhenPushed = true
        self.tabBarController!.tabBar.isHidden = true
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.tabBarController!.tabBar.isHidden = false
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - popOverPresentationController Delegate methods
    @IBAction
    func showDrugDetails(sender: UITableViewCell) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let ingredientsViewController = storyBoard.instantiateViewController(withIdentifier: "SubstanceAndClassPopUp") as! SubstanceAndClassPopUp

        let originViewRect = sender.contentView.frame
        
        let originRect: CGRect = CGRect(x: originViewRect.maxX , y: originViewRect.origin.y + 10, width: 25, height: 25)
        
        ingredientsViewController.modalPresentationStyle = .popover
        ingredientsViewController.preferredContentSize = CGSize(width: 280, height: 144)
        ingredientsViewController.theDrug = theNewDrug
        
        
        let popUpController = ingredientsViewController.popoverPresentationController
        popUpController!.permittedArrowDirections = .any
        popUpController!.sourceView = sender.contentView
        popUpController?.sourceRect = originRect
        popUpController!.delegate = self
        
        // do this AFTER setting up the PopoverPresentationController or it won't work as popUP on iPhone!
        self.present(ingredientsViewController, animated: true, completion: nil)
    }
    
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // MARK: - Custom functions
    
    func saveAction () {
        
        if theNewDrug?.notes != nil {
            theNewDrug!.notes = notesTextView.text
        }
        if textFieldOpen.isOpen {
            print("need to save open textField")
            _ = textFieldShouldReturn(textFieldOpen.textField )
        }
        
        theNewDrug!.storeObjectAndNotifications()
        
        performSegue(withIdentifier: "returnToDrugListAndSave", sender: self)
        
    }
    
    
    func cancelAction() {
        
        if drugFromList == nil { // this protects against deleting an existing drug that was loaded for editing (rather than a new drug)
            self.managedObjectContext.delete(theNewDrug!)
        }
        
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    
    func initiateClassObjects() {
        
        datePicker = {
            let picker = UIDatePicker()
            picker.minuteInterval = 1 // *** CHANGE THIS BACK TO FIVE
            picker.locale = NSLocale.current
            return picker
        }()
        
        timesPicker = {
            let picker = UIDatePicker()
            picker.locale = NSLocale.current
            picker.datePickerMode = UIDatePickerMode.time
            picker.minuteInterval = 1 // *** CHANGE THIS BACK TO FIVE
            return picker
        }()
        
        trialDurationPicker = {
            let picker = UIPickerView()
            trialDurationPickerValues = [["1","2","3","4","5","6","7","8","9","10","11","12"], ["off","days", "weeks","months"]]
            trialDurationChosen = (1,"")
            picker.delegate = self
            picker.dataSource = self
            return picker
        }()
        
        frequencyPicker = {
            let picker = UIPickerView()
            frequencyPickerValues = [String]()
            for aSet in theNewDrug!.frequencyTerms {
                let (term,_) = aSet
                frequencyPickerValues.append(term)
            }
            frequencyChosen = frequencyPickerValues[5]
            picker.delegate = self
            picker.dataSource = self
            return picker
        }()
        
        drugNamePicker = {
            let picker = UIPickerView()
            drugNamePickerValues = [""]
            drugIndexChosen = 0
            picker.delegate = self
            picker.dataSource = self
            return picker
        }()
        
        numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        
        notesTextView = UITextView()
    }
    
    func switchControlAction(sender: UISwitch) {
        
        if sender.isOn {
            theNewDrug!.regularlyVar = true
            
            cellRowHelper.insertNonPickerCellRow(forIndexPath: cellRowHelper.pathForCellInAllCellArray(cellType: "timesCell"))
            tableView.insertRows(at: [cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell")], with: UITableViewRowAnimation.automatic)
            
            if let timesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell")) {
                (timesCell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.timesString()
            }
            if let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell")) {
                (dosesCell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.dosesString()
                dosesCell.accessoryType = .disclosureIndicator
            }
            
        } else {
            theNewDrug!.regularlyVar = false
            
            let indexPath = cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell")
            cellRowHelper.removeVisibleRow(row: indexPath.row, inSection: indexPath.section)
            tableView.deleteRows(at: [indexPath], with: .top)
            
            if let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell")) {
                (dosesCell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.dosesString()
                dosesCell.accessoryType = .none
            }
            
        }
        if let frequencyCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "frequencyCell")) {
            (frequencyCell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.frequencyString()
        }
        
    }
    
    func doseUnitSelection(sender: UISegmentedControl) {
        
        theNewDrug!.saveDoseUnit(index: sender.selectedSegmentIndex)
        let cell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "doseUnitCell"))
        (cell?.contentView.viewWithTag(controlTag) as! UISegmentedControl).selectedSegmentIndex = theNewDrug!.doseUnitIndex()
        let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell"))
        (dosesCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.dosesString()
        
    }
    
    @objc func dropDownButtonFunction() {
        
        let changeAtPath = IndexPath(row: 1, section: 0)
        let nameCellIndexpath = IndexPath(row: 0, section: 0)
        
        if cellRowHelper.pickerViewVisible(name: "namePickerCell") {
            cellRowHelper.removeVisibleRow(row: changeAtPath.row, inSection: changeAtPath.section)
            drugNamePicker.removeFromSuperview()
            tableView.deleteRows(at: [changeAtPath], with: .automatic)

            // drugNamePickerValues[0] needs correction taking into account selection in drugNamePicker
            if let selectedPublicDrug = drugDictionary.returnSelectedPublicDrug(index: drugIndexChosen) {
                theNewDrug!.getDetailsFromPublicDrug(publicDrug: selectedPublicDrug, nameChosen: drugNamePickerValues[drugNamePicker.selectedRow(inComponent: 0)])
                tableView.reloadData()
                let cell = tableView.cellForRow(at: nameCellIndexpath)
                (cell?.contentView.viewWithTag(titleTag) as! UILabel).textColor = UIColor.gray
                (cell?.contentView.viewWithTag(titleTag) as! UILabel).text = drugNamePickerValues[drugNamePicker.selectedRow(inComponent: 0)]
                
                // need to complete and resolve name textField as the name text may only have been entered partially when dropDown menu activated and selected. This should 'close' and complete the textField entry
            }

        } else {
            let cell = tableView.cellForRow(at: nameCellIndexpath)
            cellRowHelper.insertVisibleRow(forIndexPath: nameCellIndexpath)
            tableView.insertRows(at: [changeAtPath], with: .top)
            (cell?.contentView.viewWithTag(titleTag) as! UILabel).textColor = UIColor.red
        }
        
    }
    
    // MARK: - Table view data source
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return cellRowHelper.numberOfSections()

    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return cellRowHelper.numberOfRowsInSection(section: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitles = ["Name, ingredients and class","Dates, Frequency & Times","Doses", "Notes"]
        return sectionTitles[section]

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath) {
        case "namePickerCell","startDatePickerCell", "endDatePickerCell", "frequencyPickerCell","timesPickerCell":
            return 210
        case "notesCell":
            return 170
        default:
            return 50
        }

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell!
        var pickerXPosition: CGFloat!
        
        let cellType: [String] = cellRowHelper.returnVisibleCellArrayAtPath(indexPath: indexPath)
        let cellName:String = cellType[0]
        let cellPrototype: String = cellType[1]
        let viewWidth: CGFloat = tableView.frame.width - 15.0
        
        cell = tableView.dequeueReusableCell(withIdentifier: cellPrototype)
        
        if isDiscontinuedDrug == true { // is old drug - not modifiable
            cell.isUserInteractionEnabled = false
        }
        
        switch cellName {
        // SECTION 0
        case "nameCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = theNewDrug!.nameVar
            if dropDownButton == nil {
                dropDownButton = cell.contentView.viewWithTag(50) as! UIButton
                dropDownButton.addTarget(self, action: #selector(self.dropDownButtonFunction), for: .touchUpInside)
                dropDownButton.isEnabled = false
            }
        case "namePickerCell":
            pickerXPosition = viewWidth - drugNamePicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            drugNamePicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            drugNamePicker.selectRow(0, inComponent: 0, animated: false)
            cell.contentView.addSubview(drugNamePicker)
            
        // SECTION 1
        case "startDateCell":
            pickerXPosition = viewWidth - datePicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Start Date"
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.startDateString()
            
        case "startDatePickerCell":
            pickerXPosition = viewWidth - datePicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            datePicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            datePicker.date = theNewDrug!.startDateVar
            cell.contentView.addSubview(datePicker)
            
        case "endDateCell":
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.endDateString()
            if theNewDrug!.endDateString() == "" {
                (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "(For how long?)"
            } else {
                (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Until"
            }
        case "endDatePickerCell":
            pickerXPosition = viewWidth - trialDurationPicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            trialDurationPicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            trialDurationPicker.selectRow(4, inComponent: 1, animated: false)
            cell.contentView.addSubview(trialDurationPicker)
            
        case "frequencyCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Frequency"
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.frequencyString()
            
        case "frequencyPickerCell":
            pickerXPosition = viewWidth - frequencyPicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            frequencyPicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            frequencyPicker.selectRow(theNewDrug!.frequencyToPickerViewRow(), inComponent: 0, animated: false)
            cell.contentView.addSubview(frequencyPicker)
            
        case "regularityCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Regularly"
            if regularitySwitch == nil {
                regularitySwitch = (cell.contentView.viewWithTag(controlTag) as! UISwitch)
                regularitySwitch.addTarget(self, action: #selector(switchControlAction(sender:)), for: UIControlEvents.valueChanged)
            }
            regularitySwitch.setOn(theNewDrug!.regularlyVar, animated: false)
            
        case "timesCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Times"
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.timesString()
            
        case "timesPickerCell":
            pickerXPosition = viewWidth - timesPicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            timesPicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            timesPicker.setDate(theNewDrug!.startDateVar, animated: false)
            cell.contentView.addSubview(timesPicker)
            
        // SECTION 2
        case "dosesCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Doses"
            doseDetailLabel = (cell.contentView.viewWithTag(detailTag) as! UILabel) // property to check wether touch is inside
            doseDetailLabel.text = theNewDrug!.dosesString()
            
            if (theNewDrug!.regularlyVar == true) { cell.accessoryType = .disclosureIndicator}
            else { cell.accessoryType = .none }
            
        case "doseUnitCell":
            if doseUnitSelection == nil {
                doseUnitSelection = cell.contentView.viewWithTag(controlTag) as! UISegmentedControl
                doseUnitSelection.selectedSegmentIndex = theNewDrug!.doseUnitIndex()
                doseUnitSelection.addTarget(self, action: #selector(doseUnitSelection(sender:)), for: UIControlEvents.valueChanged)
            } else {
                doseUnitSelection.selectedSegmentIndex = theNewDrug!.doseUnitIndex()
            }
            
        // SECTION 3
        case "notesCell":
            notesTextView = cell.contentView.viewWithTag(textViewTag) as! UITextView
            notesTextView.text = theNewDrug!.notesVar
            
        default:
            print("ERROR; cell does not exist: for indexPath \(indexPath)")
            print("cellType = \(cellType), cellPrototype = \(cellPrototype)")
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let nameCellPath = IndexPath(item: 0, section: 0)
        if indexPath == nameCellPath {
            showDrugDetails(sender: tableView.cellForRow(at: nameCellPath)!)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var titleLabel: UILabel!
        var textField: UITextField!
        var detailLabel: UILabel!
        let cell = self.tableView.cellForRow(at: indexPath)

        switch cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath) {
            
        // SECTI0N 0
        case "nameCell", "ingredientsCell", "classCell":
            
            // first check if namePicker is active
            guard !cellRowHelper.pickerViewVisible(name: "namePickerCell") else {
                return
                // do nothing as de-selection should happen via dropDown menu function or textField return
            }
            
            if textField == nil {
                textField = UITextField()
            }
            textField.isEnabled = true
            titleLabel = cell?.contentView.viewWithTag(titleTag) as! UILabel
            textField.text = titleLabel.text!
            
            if titleLabel != nil {
                titleLabel.text = ""
            }
            let spaceForTextField = (cell?.contentView.frame.width)! - titleLabel.frame.origin.x - 30.0
            textField.delegate = self
            textField.isEnabled = true
            textField.clearsOnBeginEditing = false
            textField.frame = CGRect(x: titleLabel.frame.origin.x, y: titleLabel.frame.origin.y, width: spaceForTextField, height: titleLabel.frame.height)
            textField.keyboardType = UIKeyboardType.default
            textField.returnKeyType = UIReturnKeyType.done
            textField.becomeFirstResponder()
            textField.clearButtonMode = .whileEditing
            
            if inAppStore.checkDrugFormularyAccess() {
                textField.addTarget(self, action: #selector(textFieldEntryAction(sender:)), for: UIControlEvents.editingChanged)
            }
            textField.addTarget(self, action: #selector(UITextFieldDelegate.textFieldShouldReturn(_:)), for: UIControlEvents.editingDidEnd)
            
            cell?.contentView.addSubview(textField)
            
            textFieldOpen.isOpen = true
            textFieldOpen.path = indexPath
            textFieldOpen.text = cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath)
            textFieldOpen.textField = textField
            
        // SECTION 1
        case "startDateCell":
            let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            if cellRowHelper.pickerViewVisible(name: "startDatePickerCell") {
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                cellRowHelper.removeVisibleRow(row: indexPath.row+1, inSection: indexPath.section)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                theNewDrug!.startDate = datePicker.date as NSDate?
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.startDateString()
                let endDateCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "endDateCell"))
                (endDateCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.endDateString()
                datePicker.removeFromSuperview()
            } else {
                cellRowHelper.insertVisibleRow(forIndexPath: indexPath)
                tableView.insertRows(at: [changeAtPath], with: .top)
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.red
                
                if cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath).contains("startDate") { datePicker.date = theNewDrug!.startDateVar }
                else {
                    if theNewDrug!.endDate != nil { datePicker.date = theNewDrug!.endDateVar!}
                    else { datePicker.date = Date() }
                }
            }
            
        case "endDateCell":
            let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            if cellRowHelper.pickerViewVisible(name: "endDatePickerCell") {
                let endDate$ = theNewDrug!.trialPeriodToEndDate(trialPeriodNo: trialDurationChosen.number, trialPeriodMetric: trialDurationChosen.metric)
                cellRowHelper.removeVisibleRow(row: indexPath.row+1, inSection: indexPath.section)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = endDate$
                trialDurationPicker.removeFromSuperview()
                
                if theNewDrug!.endDateString() == "" {
                    (cell?.contentView.viewWithTag(titleTag) as! UILabel).text = "(For how long?)"
                } else {
                    (cell?.contentView.viewWithTag(titleTag) as! UILabel).text = "Until"
                }
                
                
            } else {
                cellRowHelper.insertVisibleRow(forIndexPath: indexPath)
                tableView.insertRows(at: [changeAtPath], with: .top)
                (cell?.contentView.viewWithTag(titleTag) as! UILabel).text = "(For how long?)"
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.red
            }
            
        case "endDatePicker":
            print("endDatePicker can't be selected")
            
        case "frequencyCell":
            let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            if cellRowHelper.pickerViewVisible(name: "frequencyPickerCell") {
                
                cellRowHelper.removeVisibleRow(row: indexPath.row+1, inSection: indexPath.section)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                theNewDrug!.frequencyStringToTimeInterval(term: frequencyChosen)
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.frequencyString()
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                if (theNewDrug!.regularly == true) {
                    let timesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell"))
                    (timesCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.timesString()
                }
                let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell"))
                (dosesCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.dosesString()
                if theNewDrug!.numberOfDailyDoses() > 1 {
                    dosesCell?.accessoryType = .disclosureIndicator
                } else { dosesCell?.accessoryType = .none }
                frequencyPicker.removeFromSuperview()
                
            } else {
                cellRowHelper.insertVisibleRow(forIndexPath: indexPath)
                tableView.insertRows(at: [changeAtPath], with: .top)
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.red
            }
            
        case "frequencyPickerCell":
            print("frequencyPickerCell can't be selected")
        case "regularityCell":
            print("regularityCell can't be selected")
            
        // SECTION 2
        case "timesCell":
            let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            if cellRowHelper.pickerViewVisible(name: "timesPickerCell") {
                
                cellRowHelper.removeVisibleRow(row: indexPath.row+1, inSection: indexPath.section)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.timesString()
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                timesPicker.removeFromSuperview()
                
                theNewDrug!.startDateVar = timesPicker.date
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.timesString()
                
            } else {
                cellRowHelper.insertVisibleRow(forIndexPath: indexPath)
                tableView.insertRows(at: [changeAtPath], with: .top)
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.red
            }
            
        case "timesPickerCell":
            print("timesPickerCell can't be selected")
            
        case "dosesCell":
            if theNewDrug!.regularlyVar == false { // One dose only, edit directly in cellRow textField
                
                detailLabel = cell?.contentView.viewWithTag(detailTag) as! UILabel
                if textField == nil {
                    textField = UITextField()
                    textField.delegate = self
                    textField.frame = CGRect(
                        x: detailLabel.frame.origin.x - 30,
                        y: detailLabel.frame.origin.y,
                        width: detailLabel.frame.width + 30,
                        height: detailLabel.frame.height
                    )
                    textField.textAlignment = .right
                    textField.delegate = self
                    textField.isEnabled = true
                    textField.clearsOnBeginEditing = false
                    textField.keyboardType = UIKeyboardType.decimalPad
                    textField.returnKeyType = UIReturnKeyType.done
                    textField.addTarget(self, action: #selector(textFieldChangedContent(textField:)), for: UIControlEvents.editingChanged)
                    cell?.contentView.addSubview(textField)
                }
                textField.isEnabled = true
                //                    textField.clearButtonMode = .Always
                
                textFieldOpen.isOpen = true
                textFieldOpen.path = indexPath
                textFieldOpen.text = cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath)
                textFieldOpen.textField = textField
                
                textField.placeholder = numberFormatter.string(from: NSNumber(value: theNewDrug!.dosesVar[0]))
                detailLabel.text = ""
                textField.becomeFirstResponder()
                addDoneButtonToKeyboard(sender: textField)
                
                
            } else { // multiple doses, edit in separate viewController individually
                performSegue(withIdentifier: "doseDetailSegue", sender: nil)
            }
            
        case "doseUnitCell":
            print("needs development")
            
        // SECTION 3
        case "notesCell":
            print("needs development")
            
        default:
            print("cell can't be seleted") // all pickerViews!
            
        }
        
    }
    
    // MARK: - PickerView functions
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView.isEqual(trialDurationPicker) { return 2 }
        else if pickerView.isEqual(frequencyPicker) {return 1 }
        else { return 1 }

    }

    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.isEqual(trialDurationPicker) { return trialDurationPickerValues[component].count }
        else if pickerView.isEqual(frequencyPicker) {return frequencyPickerValues.count }
        else if pickerView.isEqual(drugNamePicker) { return drugNamePickerValues.count }
        else { return 0 }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.isEqual(trialDurationPicker) {
            return trialDurationPickerValues[component][row]
        }
        else if pickerView.isEqual(frequencyPicker) {
            return frequencyPickerValues[row]
        }
        else if pickerView.isEqual(drugNamePicker) { return nil }
        else { return "" }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        if pickerView.isEqual(drugNamePicker) {
            let attribute = UIFont(name: "AvenirNext-Regular", size: 11)!
            let titleText = NSAttributedString(
                string: drugNamePickerValues[row],
                attributes: [NSFontAttributeName: attribute,
                             NSUnderlineColorAttributeName: UIColor.black]
            )

            return titleText
        }
        else  { return nil }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.isEqual(trialDurationPicker) {
            if component == 1 {
                if row == 1 { trialDurationChosen.metric = "days" }
                else if row == 2 { trialDurationChosen.metric = "weeks" }
                else if row == 3 { trialDurationChosen.metric = "months" }
                else { trialDurationChosen.metric = "off" }
            }
            else {
                trialDurationChosen.number = row+1
            }
        }
        else if pickerView.isEqual(frequencyPicker) {
            frequencyChosen  = frequencyPickerValues[row]
        } else if pickerView.isEqual(drugNamePicker) {
            // pick drug from array
            drugIndexChosen = drugNamePickerIndexReferences[row]
            print("")
            print("namePickerSelection is \(drugIndexChosen), (\(drugDictionary.cloudDrugArray[drugIndexChosen].displayName))")
            print("")
           
        }
        
        
    }
    
    // MARK: - TextField functions
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        switch textFieldOpen.text{
        case "doseCell":
            textField.keyboardType = UIKeyboardType.decimalPad
        default:
            textField.returnKeyType = UIReturnKeyType.done
        }
        
        if inAppStore.checkDrugFormularyAccess() {
            textField.spellCheckingType = .no
            textField.autocorrectionType = .no
        }
    }
    
    func textFieldChangedContent(textField: UITextField) {
        textField.sizeToFit()
    }
    
    func textFieldEntryAction(sender: UITextField) {
        
        if sender.text == "" { return } // if no text was yet entered, ie. at the beginning
        
        var titleLabel: UILabel!
        
        // *** need detailLabel for dose entry!
        if let cell = tableView.cellForRow(at: textFieldOpen.path) {
            titleLabel = cell.contentView.viewWithTag(titleTag) as! UILabel
        }
        
        switch textFieldOpen.text {
        case "nameCell":
            
            let name = drugDictionary.matchingDrugNames(name: sender.text!)
            if name != nil {
                
                if titleLabel != nil {
                    titleLabel.text = name!.localizedCapitalized
                    drugNamePickerValues = drugDictionary.drugSelectionTerms
                    
                    drugNamePickerValues = [String]()
                    drugNamePickerIndexReferences = [Int]()
                    for index in drugDictionary.matchingCloudDictionaryIndexes {
                        for term in drugDictionary.cloudDrugArray[index].dictionaryTerms {
                            drugNamePickerValues.append(term)
                            drugNamePickerIndexReferences.append(index)
                        }
                    }
//                    print("")
//                    print("NewDrug.name changed")
//                    print("pickerValues are \(drugNamePickerValues)")
//                    print("corresponding indexes \(drugNamePickerIndexReferences)")
//                    print("")
                    
                   if drugNamePickerValues.count > 1 {
                        dropDownButton.isEnabled = true
                    }
                    sender.textColor = UIColor.gray
                }
            } else {
                dropDownButton.isEnabled = false
                titleLabel.text = ""
                sender.textColor = UIColor.black
            }
        default:
            return
            
        }
        
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()

        if textFieldOpen.isOpen == false {
            return false
        }
        var titleLabel: UILabel!
        let cell = self.tableView.cellForRow(at: textFieldOpen.path)
        
        if cell != nil {
            titleLabel = cell!.contentView.viewWithTag(titleTag) as! UILabel
        } else {
            print("error in NewDrug - textFieldShouldReturn function")
            print("tried to find cell, but cell is empty")
            print("textFieldOpen[0] is \(textFieldOpen.isOpen)")
            print("textFieldOpen[1] is \(textFieldOpen.path)")
            print("textFieldOpen[2] is \(textFieldOpen.text)")
            print("textFieldOpen[3] is \(textFieldOpen.textField)")
            return false
        }
        switch textFieldOpen.text {
        case "nameCell":
            
            // Check if the titleLabel field contains a string
            // this would only be the case if entered from public drugDictionary
            if titleLabel.text != "" {
                
                if let selectedPublicDrug = drugDictionary.returnSelectedPublicDrug(index: drugIndexChosen) {
                    theNewDrug!.getDetailsFromPublicDrug(publicDrug: selectedPublicDrug, nameChosen: titleLabel.text)
                    tableView.reloadData()
                }
            }
            else if let entry = textField.text {
                if entry != "" {
                    theNewDrug!.nameVar = entry
                } else { // check not empry string entered
                    textField.text = "name"
                }
                
                titleLabel.text = textField.text
            }
        case "ingredientsCell":
            if let entry = textField.text {
                theNewDrug!.ingredientsVar = entry.components(separatedBy: " ")
                titleLabel.text = textField.text
            }
        case "classCell":
            if let entry = textField.text {
                theNewDrug!.classesVar = entry.components(separatedBy: " ")
                titleLabel.text = textField.text
            }
        case "dosesCell":
            if let entry = textField.text {
                if let doseFromString = numberFormatter.number(from: entry)?.doubleValue {
                    theNewDrug!.setDoseArray(sentDose: doseFromString)
                    (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theNewDrug!.dosesString()
                }
            }
        default:
            print("textField not associated with a cellType - content not transferred to theNewDrug object")
        }
        
        textField.isEnabled = false
        textField.text = ""
        textField.textColor = UIColor.black
        textField.placeholder = ""
        textFieldOpen.isOpen = false
        textFieldOpen.text = ""
        textFieldOpen.path = IndexPath()
        
        return false
    }
    
    
    func addDoneButtonToKeyboard (sender: UITextField) {
        
        let doneButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(NewDrug.doneButton))
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
    
    func doneButton() {
        _ = textFieldShouldReturn(textFieldOpen.textField)
    }
        
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        

        if segue.identifier == "returnToDrugListAndSave" { return }
        
        if let destinationVC = segue.destination as? DosesAndReminders {
            if segue.identifier == "doseDetailSegue" {
                // convert any unsaved entries
                if theNewDrug?.notes != nil {
                    theNewDrug!.notes = notesTextView.text
                }
                if textFieldOpen.isOpen {
                    print("need to save open textField")
                    _ = textFieldShouldReturn(textFieldOpen.textField )
                }
                theNewDrug!.storeObjectAndNotifications()
                
                destinationVC.drugData = theNewDrug
                destinationVC.context = managedObjectContext
                destinationVC.callingViewController = self
            }
        } else if segue.identifier ==  "ingredientSegue" {

            if let destinationVC = segue.destination as? SubstanceAndClassPopUp {
                destinationVC.theDrug = theNewDrug
            }
        }
        else {
            print("destinationVC from NewDrug could not be cast to DosesDetailTVC")
        }

    }
    
    
}

extension NewDrug: NSFetchedResultsControllerDelegate {
    
}
