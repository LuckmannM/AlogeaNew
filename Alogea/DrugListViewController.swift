//
//  DrugListViewController.swift
//  Alogea
//
//  Created by mikeMBP on 10/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import MessageUI

class DrugListViewController: UIViewController, UISearchResultsUpdating, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    lazy var stack : CoreDataStack = {
        return (UIApplication.shared.delegate as! AppDelegate).stack
    }()
    var drugDictionary: DrugDictionary!
    var inAppStore: InAppStore!
    var searchController: UISearchController!
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        return moc
    }()
    var drugList: NSFetchedResultsController<DrugEpisode> = {
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        request.sortDescriptors = [NSSortDescriptor(key: "isCurrent", ascending: true), NSSortDescriptor(key: "regularly", ascending: false),NSSortDescriptor(key: "startDate", ascending: false),]
        
        let dL = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).stack.context, sectionNameKeyPath: "isCurrent", cacheName: nil)
        return dL
        
    }()

    var persistentStoreCoordinatorChangesObserver:NotificationCenter? {
        didSet {
            print("invoking DrugList.persistentStoreCoordinatorChangesObserver")
            oldValue?.removeObserver(self, name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: stack.coordinator)
            persistentStoreCoordinatorChangesObserver?.addObserver(self, selector: #selector(persistentStoreCoordinatorDidChangeStores(notification:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: stack.coordinator)
        }
    }

    // MARK: - View functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // stack.updateContextWithUbiquitousChangesObserver = true
        self.tabBarController?.tabBar.isHidden = false
        drugCurrentStatusUpdate()
        fetchDrugList()
        
        if drugList.fetchedObjects != nil {
            actionButton.isEnabled = true
        } else {
            actionButton.isEnabled = false
        }
        
        tableView.reloadData()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.barTintColor = ColorScheme.sharedInstance().duskBlue
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 22)!]
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        /*
         if section == 0 {
         textSize = 20 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width
         header.textLabel?.font = UIFont(name: "AvenirNext-Bold", size: textSize)
         } else {
        */
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        
        // the next hides the search bar until it is dragged down by user
        tableView.contentOffset = CGPoint(x: 0.0, y: self.tableView.tableHeaderView!.frame.size.height)
        

        drugDictionary = DrugDictionary.sharedInstance()
        inAppStore = InAppStore.sharedInstance()
        
        drugList.delegate = self

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        stack.updateContextWithUbiquitousChangesObserver = false
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        save()
    }
    
    // MARK: - Custom functions
    
    func fetchDrugList(searchText: String = "") {
        
        do {
            try drugList.performFetch()
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        
//        print("re-fetched drugList:...")
//        
//        for object in drugList.fetchedObjects! {
//            print("name = \((object as DrugEpisode).name), status = \((object as DrugEpisode).isCurrent), endDate = \((object as DrugEpisode).endDate)")
//        }
        
    }
    
    func drugCurrentStatusUpdate() {
        
        
        var currentDrugArray: [DrugEpisode]!
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let currentDrugsOnly = NSPredicate(format: "isCurrent == %@", "Current Medicines")
        fetchRequest.predicate = currentDrugsOnly
        
        do {
            currentDrugArray = try managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        
        // check if isCurrentStore has changed since last fetch
        for aDrug in currentDrugArray {
            aDrug.isCurrentUpdate()
            if aDrug.needsUpdate {
                // OPTION 2
                aDrug.isCurrentUpdate()
                //                aDrug.setValue(aDrug.isCurrentUpdate(), forKey: "isCurrentStore")
                // print("\(aDrug.name) status updated to \(aDrug.isCurrent)")
                do {
                    try aDrug.managedObjectContext!.save()
                    // print("\(aDrug.name) individually saved to moc")
                } catch let error as NSError {
                    print("error when saving single drug object, \(error), \(error.userInfo)")
                }
                
            }
        }
        
    }
    
    func persistentStoreCoordinatorDidChangeStores(notification: Notification) {
        
        do {
            try drugList.performFetch()
        } catch let error as NSError {
            print("Error fetching notes: \(error)")
        }
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        drugList = {
            let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
            request.sortDescriptors = [NSSortDescriptor(key: "isCurrent", ascending: true), NSSortDescriptor(key: "startDate", ascending: false)]
            
            // keep, important as empty string will return empty list
            if searchController.searchBar.text! != "" {
                let predicate = NSPredicate(format: "name contains[c] %@", searchController.searchBar.text!.lowercased())
                request.predicate = predicate
            }
            
            let dL = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "isCurrent", cacheName: nil)
            dL.delegate = self
            return dL
        }()
        
        do {
            try drugList.performFetch()
        } catch let error as NSError {
            print("Error fetching drugList \(error)")
        }
        
        
        tableView.reloadData() // important for life search view updates!
        
        //        let checkObjects = drugList.fetchedObjects as! [DrugEpisode]
        //        for aDrug in checkObjects {
        //            print("fetched drug: name is '\(aDrug.name)', nameStore is '\(aDrug.nameStore)'")
        //        }
        
        
    }
    
    func configureCell(cell: DrugListCell, indexPath: IndexPath) {
        
        let aDrug = drugList.object(at: indexPath) 
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = ColorScheme.sharedInstance().pearlWhite
        } else {
            cell.backgroundColor = UIColor.white
        }
        
        switch aDrug.isCurrent! {
        case "Current Medicines": // CURRENT DRUGS
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            
            if UIDevice().userInterfaceIdiom == .pad {
                cell.nameLabel.text = aDrug.returnName() + " " + aDrug.substancesForDrugList()// using 'name' results in blank for returning drugs when using searchController druglistFRC
                cell.doseLabel.text = aDrug.dosesShortString() + ".  " + aDrug.regularityLong$() + aDrug.reminderActive()
                if aDrug.endDate != nil {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()), until \(aDrug.endDateString())"
                } else {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug())"
                }
            } else {
                cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
                cell.doseLabel.text = aDrug.dosesShortString() + aDrug.reminderActive()
                if aDrug.endDate != nil {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()), until \(aDrug.endDateString())"
                } else {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()). \(aDrug.regularityShort$())"
                }
            }
            cell.ratingImageForButton(effect: aDrug.returnEffect(), sideEffects: aDrug.returnSideEffect())
            cell.ratingButton.sizeToFit()
            cell.ratingButton.addTarget(self, action: #selector(popUpRatingView(sender:)), for: .touchUpInside)
            cell.ratingButton.tag = indexPath.row
            cell.ratingButton.isEnabled = true
            
            
        case "Discontinued Medicines": // DISCONTINUED DRUGS

            if inAppStore.checkDrugFormularyAccess() == true {
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
                cell.doseLabel.text = aDrug.returnTimeOnDrug()
                if aDrug.endDate != nil {
                    cell.otherInfoLabel.text = "stopped on \(aDrug.endDateString())"
                } else { cell.otherInfoLabel.text = "no end date" }
                cell.ratingButton.isEnabled = false
                cell.ratingImageForButton(effect: aDrug.returnEffect(), sideEffects: aDrug.returnSideEffect())
            }
            else {
                cell.nameLabel.text = "Discontinued"
                cell.isUserInteractionEnabled = false
                cell.accessoryType = .none
                cell.doseLabel.text = ""
                cell.otherInfoLabel.text = "Full version required for details"
            }

        default:
            print("error in DrugListVC - section number wrong: \(indexPath.section)")
            
        }
        
    }
    
    func save() {
        
        do {
            try  managedObjectContext.save()
        }
        catch let error as NSError {
            print("Error saving \(error)", terminator: "")
        }
        
    }
    
    func debugEraseAll() {
        
        if drugList.fetchedObjects != nil {
            for object in drugList.fetchedObjects! {
                self.managedObjectContext.delete(object as NSManagedObject)
            }
            self.save()
        }
        
    }
    
    // MARK: - Export actions
    
    @IBAction func newExportDialog(sender: UIBarButtonItem) {
        
        let pdfFile = PrintPageRenderer.createPDF(fromText: self.preRenderPDFText())
       
        
        let expoController = UIActivityViewController(activityItems: [pdfFile], applicationActivities: nil)
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = expoController.popoverPresentationController
            popUpController?.permittedArrowDirections = .unknown
            popUpController?.sourceView = self.view
            popUpController?.sourceRect = self.view.frame
        }
        
        self.present(expoController, animated: true, completion: nil)

    }
    
    
    @IBAction func exportDialog(sender: UIBarButtonItem) {
        
        
        let pdfFile = PrintPageRenderer.createPDF(fromText: self.preRenderPDFText())
        
        let exportDialog = UIAlertController(title: "Export options", message: nil, preferredStyle: .actionSheet)
        
        let printAction = UIAlertAction(title: "Print", style: UIAlertActionStyle.default, handler: { (exportDialog)
            -> Void in
            
            if UIDevice().userInterfaceIdiom == .pad {
                PrintPageRenderer.printDialog(file: pdfFile, inView: self.view)
            } else {
                PrintPageRenderer.printDialog(file: pdfFile, inView: nil)
            }
            
            // print("returning to graphViewContainer from presenting print dialog")
            
        })
        
        exportDialog.addAction(printAction)
        
        if MFMailComposeViewController.canSendMail() {
            
            let emailAction = UIAlertAction(title: "Email", style: .default, handler: { (exportDialog)
                -> Void in
                
                self.exportToEmailAction(file: pdfFile)
                
            })
            
            exportDialog.addAction(emailAction)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (exportDialog)
            -> Void in
            
            return
            
        })
        
        exportDialog.addAction(cancelAction)
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = exportDialog.popoverPresentationController
            popUpController!.permittedArrowDirections = .up
            popUpController?.barButtonItem = actionButton
        }
        
        
        self.present(exportDialog, animated: true, completion: nil)
        
    }
    
    
    func preRenderPDFText() -> NSMutableAttributedString {
        
        // 1. Prepare the text
        let attributedText = NSMutableAttributedString()
        let tab2 = "  "
        let lf = "\n"
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.title1)
        let bodyDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body)
        let headerDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.title3)
        let titleFont = UIFont(descriptor: titleDescriptor, size: 16)
        let bodyFont = UIFont(descriptor: bodyDescriptor, size: 12)
        let headerFont = UIFont(descriptor: headerDescriptor, size: 14.0)
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            return formatter
        }()
        
        
        let titleString = "Medicine List" + " (" + dateFormatter.string(from: Date()) + ")" + lf + lf
        let title = NSAttributedString(
            string: titleString,
            attributes: [NSFontAttributeName: titleFont,
                         NSUnderlineColorAttributeName: UIColor.black]
        )
        attributedText.append(title)
        
        for object in drugList.fetchedObjects! {
            let drug = object 
            
            var simpleString = drug.returnName()
            let titleText = NSAttributedString(
                string: simpleString,
                attributes: [NSFontAttributeName: titleFont,
                             NSUnderlineColorAttributeName: UIColor.black]
            )
            
            simpleString = lf + tab2 + drug.dosesAndFrequencyForPrint()
            if drug.endDate != nil {
                simpleString += lf + tab2 + dateFormatter.string(from: drug.startDateVar)
                simpleString += " - " + dateFormatter.string(from: drug.endDateVar!) +  " (" + drug.returnTimeOnDrug() + ")"
            } else {
                simpleString += lf + tab2 + "started: " + dateFormatter.string(from: drug.startDateVar)
                simpleString += " (since " + drug.returnTimeOnDrug() + ")"
            }
            
            if drug.effectiveness != nil {
                simpleString += lf + tab2 + "benefit: " + drug.effectiveness!
            }
            
            if (drug.sideEffectsVar?.count)! > 0 {
                var seString = String()
                for se in drug.sideEffectsVar! {
                    seString += se + ", "
                }
                simpleString += lf + tab2 + "side effects: " + seString
            }
            let headerText = NSAttributedString(
                string: simpleString,
                attributes: [NSFontAttributeName: headerFont]
            )
            
            if drug.notes != nil {
                simpleString = lf + tab2 + drug.notes!
            }
            
            simpleString += lf
            
            
            let bodyText = NSAttributedString(
                string: simpleString,
                attributes: [NSFontAttributeName: bodyFont]
            )
            
            
            attributedText.append(titleText)
            attributedText.append(headerText)
            attributedText.append(bodyText)
        }
        
        return attributedText
        
    }
    
    func exportToEmailAction(file: NSURL) {
        
        if let attachmentData = NSData.init(contentsOf: file as URL) {
            let emailer = MFMailComposeViewController()
            emailer.mailComposeDelegate = self
            emailer.setSubject("Medicine List PDF")
            emailer.addAttachmentData(attachmentData as Data, mimeType: "application/pdf", fileName: "MedicineList.pdf")
            
            self.present(emailer, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - UIPopoverPresentationController methods
    
    func popUpRatingView(sender: UIButton) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let ratingViewController = storyBoard.instantiateViewController(withIdentifier: "DrugRatingPopUp") as! DrugRating
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let selectedDrug = drugList.object(at: indexPath)
        
        ratingViewController.effectSelected = selectedDrug.returnEffect()
        ratingViewController.sideEffectSelected = selectedDrug.returnSideEffect()
        ratingViewController.sendingButtonInRow = sender.tag
        
        ratingViewController.modalPresentationStyle = .popover
        ratingViewController.preferredContentSize = CGSize(width: 280, height: 360)
        
        
        let popUpController = ratingViewController.popoverPresentationController
        popUpController!.permittedArrowDirections = .unknown
        popUpController!.sourceView = sender
        popUpController?.sourceRect = sender.bounds
        popUpController!.delegate = self
        
        // do this AFTER setting up the PopoverPresentationController or it won't work as popUP on iPhone!
        self.present(ratingViewController, animated: true, completion: nil)
        
    }
    
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        

        if let presentedController = popoverPresentationController.presentedViewController as? DrugRating {
            
            let indexPath = IndexPath(row: presentedController.sendingButtonInRow, section: 0)
            let selectedDrug = drugList.object(at: indexPath)
            
            let cell = tableView.cellForRow(at: indexPath) as! DrugListCell
            
            selectedDrug.effectivenessVar = presentedController.effectSelected
            selectedDrug.sideEffectsVar = [presentedController.sideEffectSelected]
            selectedDrug.saveEffectAndSideEffects()
            
            cell.ratingImageForButton(effect: presentedController.effectSelected, sideEffects: presentedController.sideEffectSelected)
            // tableView.reloadRows(at: [indexPath], with: .automatic)
            
            save()
        } else {
            // return from deleteAlertController on iPad only
            
        }

        
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "createNew" {
            if inAppStore.checkDrugFormularyAccess() == false {
                
                let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
                request.predicate = NSPredicate(format: "isCurrent = %@", "Current Medicines")
                
                var currentDrugs: [DrugEpisode]?
                do {
                    currentDrugs = try managedObjectContext.fetch(request)
                }
                catch let error as NSError {
                    print("error fetching earliest selected event date in EventsDataController: \(error)")
                }
                
//                print("fetched current drugs")
//                print("there are \(currentDrugs?.count) drugs")
                if currentDrugs == nil { return true }
                
                if currentDrugs!.count > 0 {
                    
                    let purchaseAlert = UIAlertController(title: "Free version limit", message: "To add more medicines please purchase the 'No Limits' or 'Unlimited Medicines' expansion.   Alternatively, you can end or delete the existing medicine and create another", preferredStyle: .actionSheet)
                    
                    let goToStore = UIAlertAction(title: "View expansion options", style: UIAlertActionStyle.default, handler: { (storeAction)
                        -> Void in
                        
                        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                        let storeView = storyBoard.instantiateViewController(withIdentifier: "StoreViewID") as! StoreView
                        storeView.rootView = self
                        
                        storeView.modalPresentationStyle = .popover
                        storeView.preferredContentSize = CGSize(width: 280, height: 360)
                        
                        self.navigationController!.pushViewController(storeView, animated: true)
                        
                    })
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (cancelAction)
                        -> Void in
                        
                        //do nothing and dimiss
                    })
                    
                    purchaseAlert.addAction(goToStore)
                    purchaseAlert.addAction(cancelAction)
                    
                    if UIDevice().userInterfaceIdiom == .pad {
                        let popUpController = purchaseAlert.popoverPresentationController
                        popUpController!.permittedArrowDirections = .up
                        popUpController?.barButtonItem = addButton
                    }
                    
                    
                    self.present(purchaseAlert, animated: true, completion: nil)

                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let nextViewController = segue.destination as? NewDrug {
            nextViewController.rootViewController = self
            nextViewController.drugDictionary = drugDictionary
            
            if segue.identifier == "editDrug" {
                if let indexPath = sender {
                    // if creating new drug don't pass anything and a new will be generated in nextTVC
                    nextViewController.drugFromList = drugList.object(at: indexPath as! IndexPath)
                }
            }
        } else {
            print("error createNew segue: destinationViewcontrolle not defined")
        }

    }
    
    @IBAction
    func returnFromNewDrugTVC(segue:UIStoryboardSegue) {
        
        // print("DrugList - returning from NewDrug")
        
        save()
        tableView.reloadData()
        
        /*
         print("returning from 'New Drug' and saving")
         print("drugList now has \(drugList.fetchedObjects?.count) drugs")
         for object in drugList.fetchedObjects! {
         if let drug = object as DrugEpisode? {
         print("name: \(drug.name)")
         print("startDate: \(drug.startDate)")
         print("isCurrent: \(drug.isCurrent)")
         print("----------")
         }
         }
         */

        
    }
    
    
}

// MARK: - TableView DataSource

extension DrugListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sections = drugList.sections else {
            return 0
        }
        // print("drugList numberOfSections = \(sections.count)")
        return sections.count

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sectionInfo = drugList.sections?[section] {
            // print("drugList numberOfObjects in section \(section) = \(sectionInfo.numberOfObjects)")
            return sectionInfo.numberOfObjects
        }
        else {
            return 0
        }
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "drugListCell", for: indexPath)
                as! DrugListCell
        
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    /*
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60 )
        let header =
        
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 20, width: 0, height:0))
        
        
        
    }
    */
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        var textSize: CGFloat!

        textSize = 20 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width
        header.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: textSize)
        header.textLabel?.sizeToFit()
        
        header.textLabel?.textColor = UIColor.white
    }

    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let sectionInfo = drugList.sections?[section] {
            return sectionInfo.name
        } else {
            return ""
        }

    }

}

// MARK: - TableView Delegate


extension DrugListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // action when tapping a row - segue to detailView to modify drug or
        // segue to ratingViewController to rate
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        performSegue(withIdentifier: "editDrug", sender: indexPath)

    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let endAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "End", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
                
                /*
                modifying the last remaining object in a section (resulting in section delete) in the below way is interpreted by drugList FRC as and .update action, as while if an object remains in section (no section delete) the modification is a .move action.
                This is because - when deleting the last row in section 0 ('Current Medicines')  - section 1 ('Discontinued Medicines') becomes section 0 and indexPath 0,0 remains 0,0 but is in the 'new' section 0
                 However, the 'new' section 0 doesn't seem to receive a message that one row has been inserted in the process
                in order to display correctly 
                option 1 - the FRC .update method should use delete/insert or
                option 2 - a new object/ copy of the old should be inserted and the old deleted
                */
                
                guard (self.drugList.sections?[indexPath.section]) != nil  else {
                    print("error in DrugList.editRowActions.endAction - section \(indexPath.section) doesn't exist")
                    return
                }
                
                let drugToStop = self.drugList.object(at: indexPath)
                drugToStop.storeObjectForEnding(endingDate: Date()) // essential for FRC to change display

                self.fetchDrugList()

        } )
        
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler:
            { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
                
                let deleteAlert = UIAlertController(title: "Delete records?", message: "This will remove the current and any previous records of this medicine. Use End instead to archive", preferredStyle: .actionSheet)
                
                let proceedAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default, handler: { (deleteAlert)
                    -> Void in
                    
                    let objectToDelete = self.drugList.object(at: indexPath) 
                    
                    objectToDelete.cancelNotifications()
                    self.managedObjectContext.delete(objectToDelete)
                    self.save()
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (deleteAlert)
                    -> Void in
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                })
                
                deleteAlert.addAction(proceedAction)
                deleteAlert.addAction(cancelAction)
                
                // iPads have different requirements for AlertControllers!
                if UIDevice().userInterfaceIdiom == .pad {
                    let cell = tableView.cellForRow(at: indexPath)
                    let popUpController = deleteAlert.popoverPresentationController
                    popUpController!.permittedArrowDirections = .up
                    popUpController!.sourceView = self.view
                    popUpController!.sourceRect = (cell?.contentView.bounds)!
                }
                
                self.present(deleteAlert, animated: true, completion: nil)
        })
        
        deleteAction.backgroundColor = UIColor.red
        endAction.backgroundColor = UIColor.orange
        
        let sectionInfo = drugList.sections?[indexPath.section]
        
        if sectionInfo?.name == "Current Medicines" { return [endAction, deleteAction] }
        else { return [deleteAction] }
    }
    
}

// MARK: - FetchedResultController functions


extension DrugListViewController: NSFetchedResultsControllerDelegate {
    
   
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("drugList FRC will change content")
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        tableView.endUpdates()
        print("drugList FRC finished changing content")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            // using .moveRow() causes a problem as the moved row fails to fade away the rowActionMenu
            // using .deselectRow doesn't help
        }
        
        if drugList.fetchedObjects != nil {
            actionButton.isEnabled = true
        } else {
            actionButton.isEnabled = false
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        
        let indexSet = NSIndexSet(index: sectionIndex) as IndexSet
        switch type {
        case .insert:
            // print("inserting section \(sectionInfo.name)")
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            // print("deleting section \(sectionInfo.name)")
           tableView.deleteSections(indexSet, with: .automatic)
        case .update:
            // print("updating section \(sectionInfo.name)")
            tableView.reloadSections([sectionIndex], with: .automatic)
        case .move:
            print("move section \(sectionInfo.name) at index \(sectionIndex)")
        }
    }
    
    
}

extension DrugListViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        //        switch result {
        //        case MFMailComposeResultCancelled:
        //            print("email cancelled")
        //        case MFMailComposeResultSent:
        //            print("email sent")
        //        case MFMailComposeResultSaved:
        //            print("email saved")
        //        default:
        //            print("email result default")
        //        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
}

