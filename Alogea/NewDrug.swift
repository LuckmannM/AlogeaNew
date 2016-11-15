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

typealias TrialDuration = (number:Int, metric: String)

class NewDrug: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    
    var rootViewController: DrugListViewController!
    
    var drugFromList: DrugEpisode?
    lazy var theDrug: DrugEpisode? =
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
    
    var trialDurationChosen: TrialDuration!
    var frequencyChosen: String!
    var drugNameChosen: String!
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
        
        
        isDiscontinuedDrug = false
        if let theEnd = theDrug!.endDate {
            let now = Date()
            if theEnd.compare(now) == .orderedAscending { // is old drug - not modifiable
                isDiscontinuedDrug = true
                //                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "saveAction")
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(cancelAction))
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(saveAction))
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction))
            }
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(saveAction))
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction))
        }
        
        print("drug in NewDrug is \(theDrug?.name)")
        
        cellRowHelper = NewDrugHelper()
        cellRowHelper.initHelper(regularly: theDrug!.regularly)
        
//        inAppStore  = InAppStore.sharedInstance()
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
        
        print("drugDetails popOver not yet implemented")
        
        /*
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let ingredientsViewController = storyBoard.instantiateViewControllerWithIdentifier("IngredientsPopUp") as! Ingredient_ClassTVC

        let originViewRect = sender.contentView.frame
        
        let originRect: CGRect = CGRect(x: originViewRect.maxX , y: originViewRect.origin.y + 10, width: 25, height: 25)
        
        ingredientsViewController.modalPresentationStyle = .Popover
        ingredientsViewController.preferredContentSize = CGSizeMake(280, 144)
        ingredientsViewController.theDrug = theDrug
        
        
        let popUpController = ingredientsViewController.popoverPresentationController
        popUpController!.permittedArrowDirections = .Any
        popUpController!.sourceView = sender.contentView
        popUpController?.sourceRect = originRect
        popUpController!.delegate = self
        
        // do this AFTER setting up the PopoverPresentationController or it won't work as popUP on iPhone!
        self.presentViewController(ingredientsViewController, animated: true, completion: nil)
       */
    }
    
    
    private func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        
        print("return from popOver")
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
    // MARK: - Custom functions
    
    func saveAction () {
        
        if theDrug?.notes != nil {
            theDrug!.notes = notesTextView.text
        }
        if textFieldOpen.isOpen {
            print("need to save open textField")
            textFieldShouldReturn(textField: textFieldOpen.textField )
        }
        
        theDrug!.storeObjectAndNotifications()
        
        performSegue(withIdentifier: "returnToDrugListAndSave", sender: self)
        
    }
    
    
    func cancelAction() {
        
        if drugFromList == nil {
            self.managedObjectContext.delete(theDrug!)
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
            for aSet in theDrug!.frequencyTerms {
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
            drugNameChosen = drugNamePickerValues[0]
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
            theDrug!.regularly = true
            
            cellRowHelper.insertNonPickerCellRow(forIndexPath: cellRowHelper.pathForCellInAllCellArray(cellType: "timesCell"))
            tableView.insertRows(at: [cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell")], with: UITableViewRowAnimation.automatic)
            
            if let timesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell")) {
                (timesCell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.timesString()
            }
            if let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell")) {
                (dosesCell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.dosesString()
                dosesCell.accessoryType = .disclosureIndicator
            }
            
        } else {
            theDrug!.regularly = false
            
            let indexPath = cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell")
            cellRowHelper.removeVisibleRow(row: indexPath.row, inSection: indexPath.section)
            tableView.deleteRows(at: [indexPath], with: .top)
            
            if let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell")) {
                (dosesCell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.dosesString()
                dosesCell.accessoryType = .none
            }
            
        }
        if let frequencyCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "frequencyCell")) {
            (frequencyCell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.frequencyString()
        }
        
    }
    
    func doseUnitSelection(sender: UISegmentedControl) {
        
        theDrug!.saveDoseUnit(index: sender.selectedSegmentIndex)
        let cell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "doseUnitCell"))
        (cell?.contentView.viewWithTag(controlTag) as! UISegmentedControl).selectedSegmentIndex = theDrug!.doseUnitIndex()
        let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell"))
        (dosesCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.dosesString()
        
    }
    
    @objc func dropDownButtonFunction(sender: UIButton) {
        
        let changeAtPath = IndexPath(row: 1, section: 0)
        let nameCellIndexpath = IndexPath(row: 0, section: 0)
        
        //        if cellRowHelper.pickerViewVisible("namePickerCell") {
        //            let cell = tableView.cellForRowAtIndexPath(changeAtPath)
        //            (cell?.contentView.viewWithTag(titleTag) as! UILabel).textColor = UIColor.grayColor()
        //            cellRowHelper.removeVisibleRow(nameCellIndexpath.row+1, inSection: 0)
        //            tableView.deleteRowsAtIndexPaths([changeAtPath], withRowAnimation: .Top)
        //
        //            // drugNamePickerValues[0] needs correction taking into account selection in drugNamePicker
        //            if let selectedPublicDrug = drugDictionary.returnSelectedPublicDrug(drugNameChosen) {
        //                theDrug!.getDetailsFromPublicDrug(selectedPublicDrug)
        //                tableView.reloadData()
        //            }
        //
        //            drugNamePicker.removeFromSuperview()
        //        } else {
        let cell = tableView.cellForRow(at: nameCellIndexpath)
        cellRowHelper.insertVisibleRow(forIndexPath: nameCellIndexpath)
        tableView.insertRows(at: [changeAtPath], with: .top)
        (cell?.contentView.viewWithTag(titleTag) as! UILabel).textColor = UIColor.red
        //        }
        
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
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = theDrug!.name
            if dropDownButton == nil {
                dropDownButton = cell.contentView.viewWithTag(50) as! UIButton
                dropDownButton.addTarget(self, action: #selector(self.dropDownButtonFunction(sender:)), for: .touchUpInside)
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
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.startDateString()
            
        case "startDatePickerCell":
            pickerXPosition = viewWidth - datePicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            datePicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            datePicker.date = theDrug!.startDateVar
            cell.contentView.addSubview(datePicker)
            
        case "endDateCell":
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.endDateString()
            if theDrug!.endDateString() == "" {
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
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.frequencyString()
            
        case "frequencyPickerCell":
            pickerXPosition = viewWidth - frequencyPicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            frequencyPicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            frequencyPicker.selectRow(theDrug!.frequencyToPickerViewRow(), inComponent: 0, animated: false)
            cell.contentView.addSubview(frequencyPicker)
            
        case "regularityCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Regularly"
            if regularitySwitch == nil {
                regularitySwitch = (cell.contentView.viewWithTag(controlTag) as! UISwitch)
                regularitySwitch.addTarget(self, action: #selector(switchControlAction(sender:)), for: UIControlEvents.valueChanged)
            }
            regularitySwitch.setOn(theDrug!.regularly, animated: false)
            
        case "timesCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Times"
            (cell.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.timesString()
            
        case "timesPickerCell":
            pickerXPosition = viewWidth - timesPicker.frame.width
            if pickerXPosition < 0 {
                pickerXPosition = 0.0
            }
            timesPicker.frame.origin = CGPoint(x: pickerXPosition, y: 0)
            timesPicker.setDate(theDrug!.startDateVar, animated: false)
            cell.contentView.addSubview(timesPicker)
            
        // SECTION 2
        case "dosesCell":
            (cell.contentView.viewWithTag(titleTag) as! UILabel).text = "Doses"
            doseDetailLabel = (cell.contentView.viewWithTag(detailTag) as! UILabel) // property to check wether touch is inside
            doseDetailLabel.text = theDrug!.dosesString()
            if (theDrug!.regularly == true) { cell.accessoryType = .disclosureIndicator}
            else { cell.accessoryType = .none }
            
        case "doseUnitCell":
            if doseUnitSelection == nil {
                doseUnitSelection = cell.contentView.viewWithTag(controlTag) as! UISegmentedControl
                doseUnitSelection.selectedSegmentIndex = theDrug!.doseUnitIndex()
                doseUnitSelection.addTarget(self, action: #selector(doseUnitSelection(sender:)), for: UIControlEvents.valueChanged)
            }
            
            
        // SECTION 3
        case "notesCell":
            notesTextView = cell.contentView.viewWithTag(textViewTag) as! UITextView
            notesTextView.text = theDrug!.notes
            
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
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var titleLabel: UILabel!
        var textField: UITextField!
        var detailLabel: UILabel!
        let cell = self.tableView.cellForRow(at: indexPath)
        
        switch cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath) {
            
        // SECTI0N 0
        case "nameCell", "ingredientsCell", "classCell":
            
            // first check if namePicker is active
            if cellRowHelper.pickerViewVisible(name: "namePickerCell") {
                let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
                
                (cell?.contentView.viewWithTag(titleTag) as! UILabel).textColor = UIColor.black
                cellRowHelper.removeVisibleRow(row: changeAtPath.row, inSection: 0)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                // drugNamePickerValues[0] needs correction taking into account selection in drugNamePicker
                if let selectedPublicDrug = drugDictionary.returnSelectedPublicDrug(name: drugNameChosen) {
                    theDrug!.getDetailsFromCloudDrug(publicDrug: selectedPublicDrug)
                    //                        let indexSet = NSIndexSet(index: 0)
                    tableView.reloadData()
                }
                
                drugNamePicker.removeFromSuperview()
            }
                // ... if not, active name textField
            else {
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
            }
            //
            //            case "ingredientPickerViewCell":
            //                print("needs development")
            //
            //
            //            case "classPickerCell":
            //                print("needs development")
            
        // SECTION 1
        case "startDateCell":
            let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            if cellRowHelper.pickerViewVisible(name: "startDatePickerCell") {
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                cellRowHelper.removeVisibleRow(row: indexPath.row+1, inSection: indexPath.section)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                theDrug!.startDate = datePicker.date as NSDate?
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.startDateString()
                let endDateCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "endDateCell"))
                (endDateCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.endDateString()
                datePicker.removeFromSuperview()
            } else {
                cellRowHelper.insertVisibleRow(forIndexPath: indexPath)
                tableView.insertRows(at: [changeAtPath], with: .top)
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.red
                
                if cellRowHelper.returnVisibleCellTypeAtPath(indexPath: indexPath).contains("startDate") { datePicker.date = theDrug!.startDateVar }
                else {
                    if theDrug!.endDate != nil { datePicker.date = theDrug!.endDateVar!}
                    else { datePicker.date = Date() }
                }
            }
            
        case "endDateCell":
            let changeAtPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            if cellRowHelper.pickerViewVisible(name: "endDatePickerCell") {
                let endDate$ = theDrug!.trialPeriodToEndDate(trialPeriodNo: trialDurationChosen.number, trialPeriodMetric: trialDurationChosen.metric)
                cellRowHelper.removeVisibleRow(row: indexPath.row+1, inSection: indexPath.section)
                tableView.deleteRows(at: [changeAtPath], with: .top)
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = endDate$
                trialDurationPicker.removeFromSuperview()
                
                if theDrug!.endDateString() == "" {
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
                
                theDrug!.frequencyStringToTimeInterval(term: frequencyChosen)
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.frequencyString()
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                if (theDrug!.regularly == true) {
                    let timesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "timesCell"))
                    (timesCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.timesString()
                }
                let dosesCell = self.tableView.cellForRow(at: cellRowHelper.returnPathForCellTypeInVisibleArray(cellType: "dosesCell"))
                (dosesCell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.dosesString()
                if theDrug!.numberOfDailyDoses() > 1 {
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
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.timesString()
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.gray
                timesPicker.removeFromSuperview()
                
                theDrug!.startDateVar = timesPicker.date
                
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.timesString()
                
            } else {
                cellRowHelper.insertVisibleRow(forIndexPath: indexPath)
                tableView.insertRows(at: [changeAtPath], with: .top)
                (cell?.contentView.viewWithTag(detailTag) as! UILabel).textColor = UIColor.red
            }
            
        case "timesPickerCell":
            print("timesPickerCell can't be selected")
            
        case "dosesCell":
            if theDrug!.regularly == false { // One dose only, edit directly in cellRow textField
                
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
                
                textField.placeholder = numberFormatter.string(from: NSNumber(value: theDrug!.dosesVar[0]))
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
    
    private func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.isEqual(trialDurationPicker) { return trialDurationPickerValues[component][row] }
        else if pickerView.isEqual(frequencyPicker) {return frequencyPickerValues[row] }
        else if pickerView.isEqual(drugNamePicker) { return drugNamePickerValues[row] }
        else { return "" }
        
    }
    
    private func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
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
            drugNameChosen = drugNamePickerValues[row]
        }
        
        
    }
    
    // MARK: - TextField functions
    
    private func textFieldDidBeginEditing(textField: UITextField) {
        
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
            //                let name = drugDictionary.matchingDrugNames(sender.text!)
            //                if name != "" {
            //                    if titleLabel != nil {
            //                        titleLabel.text = name
            //                        sender.textColor = UIColor.grayColor()
            //                    }
            //                }
            
            //                if let cell = tableView.cellForRowAtIndexPath(textFieldOpen[1] as! IndexPath) {
            //                    dropDownButton = cell.contentView.viewWithTag(50) as! UIButton
            //                }
            
            var names = drugDictionary.matchingDrugNames(name: sender.text!)
            if names.count > 0 {
                
                // Capitalise first character
                for i in 0 ..< names.count {
                    names[i] = (names[i] as NSString).substring(to: 1).uppercased() + (names[i] as NSString).substring(from: 1)
                }
                
                if titleLabel != nil {
                    titleLabel.text = names[0]
                    drugNamePickerValues = names
                    if names.count > 1 {
                        dropDownButton.isEnabled = true
                    }
                    print("drugNamePickerValues are \(drugNamePickerValues)")
                    sender.textColor = UIColor.gray
                }
            }
                
            else {
                dropDownButton.isEnabled = false
                titleLabel.text = ""
                sender.textColor = UIColor.black
            }
        default:
            return
            
        }
        
    }
    
    
    private func textFieldShouldReturn(textField: UITextField) -> Bool {
        
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
        //        let textField = cell?.contentView.viewWithTag(textFieldTag) as! UITextField
        
        switch textFieldOpen.text {
        case "nameCell":
            
            // Check if the titleLabel field contains a string
            // this would only be the case if entered from public drugDictionary
            if titleLabel.text != "" {
                
                if let selectedPublicDrug = drugDictionary.returnSelectedPublicDrug(name: titleLabel.text!) {
                    theDrug!.getDetailsFromCloudDrug(publicDrug: selectedPublicDrug)
                    tableView.reloadData()
                }
            }
                // if titleLabel = "" as set in didSelectRow then take text entered in textField as name
            else if let entry = textField.text {
                if entry != "" {
                    theDrug!.nameVar = entry
                } else { // check not empry string entered
                    textField.text = "name"
                }
                
                titleLabel.text = textField.text
            }
        case "ingredientsCell":
            if let entry = textField.text {
                theDrug!.ingredientsVar = entry.components(separatedBy: " ")
                titleLabel.text = textField.text
            }
        case "classCell":
            if let entry = textField.text {
                theDrug!.classesVar = entry.components(separatedBy: " ")
                titleLabel.text = textField.text
            }
        case "dosesCell":
            if let entry = textField.text {
                if let doseFromString = numberFormatter.number(from: entry)?.doubleValue {
                    theDrug!.setDoseArray(sentDose: doseFromString)
                    (cell?.contentView.viewWithTag(detailTag) as! UILabel).text = theDrug!.dosesString()
                }
            }
        default:
            print("textField not associated with a cellType - content not transferred to theDrug object")
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
        textFieldShouldReturn(textField: textFieldOpen.textField)
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: IndexPath, toIndexPath: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /*
        if segue.identifier == "returnToDrugListAndSave" { return }
        
        if let destinationVC = segue.destinationViewController as? DosesDetailTableViewController {
            if segue.identifier == "doseDetailSegue" {
                destinationVC.drugData = theDrug
                destinationVC.context = context
                destinationVC.callingViewController = self
            }
        } else if segue.identifier ==  "ingredientSegue" {
            if let destinationVC = segue.destinationViewController as? Ingredient_ClassTVC {
                destinationVC.theDrug = theDrug
            }
        }
            
        else {
            print("destinationVC from NewDrug could not be cast to DosesDetailTVC")
        }
        */
    }
    
    
}

extension NewDrug: NSFetchedResultsControllerDelegate {
    
}