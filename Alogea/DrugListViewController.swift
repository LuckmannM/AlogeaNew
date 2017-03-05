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
//    var drugDictionary: DrugDictionary!
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
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.barTintColor = ColorScheme.sharedInstance().duskBlue
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 22)!]
        self.navigationController?.navigationBar.tintColor = UIColor.white
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
        

        
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        
        // the next hides the search bar until it is dragged down by user
        tableView.contentOffset = CGPoint(x: 0.0, y: self.tableView.tableHeaderView!.frame.size.height)
        
        inAppStore = InAppStore.sharedInstance()
        drugList.delegate = self


    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        stack.updateContextWithUbiquitousChangesObserver = false
        
    }
    

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        
        if UIDevice().userInterfaceIdiom == .phone {
            coordinator.animateAlongsideTransition(in: nil, animation: nil, completion: {
                (context: UIViewControllerTransitionCoordinatorContext) -> Void in
                    self.tableView.reloadData()
            })
        }
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
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 1", showInVC: self, systemError: error)
        }
    }
    
    func drugCurrentStatusUpdate() {
        
        
        var currentDrugArray: [DrugEpisode]!
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let currentDrugsOnly = NSPredicate(format: "isCurrent == %@", "Current Medicines")
        fetchRequest.predicate = currentDrugsOnly
        
        do {
            currentDrugArray = try managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 2", showInVC: self, systemError: error)
        }
        
        // check if isCurrentStore has changed since last fetch
        for aDrug in currentDrugArray {
            aDrug.isCurrentUpdate()
            if aDrug.needsUpdate {
                // OPTION 2
                aDrug.isCurrentUpdate()
                do {
                    try aDrug.managedObjectContext!.save()
                } catch let error as NSError {
                    ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 3", showInVC: self, systemError: error, errorInfo:"error when saving single drug object")
                }
                
            }
        }
        
    }
    
    func persistentStoreCoordinatorDidChangeStores(notification: Notification) {
        
        do {
            try drugList.performFetch()
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 4", showInVC: self, systemError: error)
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
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 5", showInVC: self, systemError: error)
        }
        
        tableView.reloadData() // important for life search view updates!
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
            
            if UIDevice().userInterfaceIdiom == .phone && (self.view.frame.size.height > self.view.frame.size.width) {
                // iPhone in portrait - less space
                cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
                cell.doseLabel.text = aDrug.dosesShortString() + aDrug.reminderActive()
                if aDrug.endDateVar != nil {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()); stop \(aDrug.endDateString())"
                } else {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug())"
                }
                
            } else {
                // iPad or iPhone landscape  - more space to display
                cell.nameLabel.text = aDrug.returnName() + " " + aDrug.substancesForDrugList()// using 'name' results in blank for returning drugs when using searchController druglistFRC
                cell.doseLabel.text = aDrug.dosesShortString() + ", " + aDrug.regularityLong$() + aDrug.reminderActive()
                if aDrug.endDateVar != nil {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()), until \(aDrug.endDateString()). \(aDrug.countTaken())"
                } else {
                    cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()). \(aDrug.countTaken())"
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
                
                
//                cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
//                cell.doseLabel.text = aDrug.returnTimeOnDrug()
//                if aDrug.endDate != nil {
//                    cell.otherInfoLabel.text = "stopped on \(aDrug.endDateString())"
//                } else { cell.otherInfoLabel.text = "no end date" }
                
                if UIDevice().userInterfaceIdiom == .phone && (self.view.frame.size.height > self.view.frame.size.width) {
                    // iPhone in portrait - less space
                    cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
                    cell.doseLabel.text = aDrug.dosesShortString()
                    if aDrug.endDateVar != nil {
                        cell.otherInfoLabel.text = "stopped on \(aDrug.endDateString())"
                    } else {
                        cell.otherInfoLabel.text = "no end date"
                    }
                    
                } else {
                    // iPad or iPhone landscape  - more space to display
                    cell.nameLabel.text = aDrug.returnName() + " " + aDrug.substancesForDrugList()// using 'name' results in blank for returning drugs when using searchController druglistFRC
                    cell.doseLabel.text = aDrug.dosesShortString() + ", " + aDrug.regularityLong$()
                    if aDrug.endDateVar != nil {
                        cell.otherInfoLabel.text = "Stopped on \(aDrug.endDateString()), taken for \(aDrug.returnTimeOnDrug()). \(aDrug.countTaken(fromDate: aDrug.startDateVar, toDate: aDrug.endDateVar))"
                    } else {
                        cell.otherInfoLabel.text = "Taken for \(aDrug.returnTimeOnDrug()). \(aDrug.countTaken())"
                    }
                }

                
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
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 6", showInVC: self, errorInfo:"error in DrugListVC - section number wrong: \(indexPath.section)")
        }
        
    }
    
    func save() {
        
        do {
            try  managedObjectContext.save()
        }
        catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 7", showInVC: self, systemError: error)
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
        
        
        let titleString = "ALOGEA® Medicines List" + " (" + dateFormatter.string(from: Date()) + ")" + lf + lf
        let title = NSAttributedString(
            string: titleString,
            attributes: [NSFontAttributeName: titleFont,
                         NSUnderlineColorAttributeName: UIColor.black,
                         NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        )
        attributedText.append(title)
        
        for object in drugList.fetchedObjects! {
            let drug = object 
            
            var simpleString = drug.returnName()
            let titleText = NSAttributedString(
                string: simpleString,
                attributes: [NSFontAttributeName: titleFont,
                             NSUnderlineColorAttributeName: UIColor.black,
                             NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
            )
            
            simpleString = lf + tab2 + drug.dosesAndFrequencyForPrint()
            
            if drug.endDateVar != nil {
                simpleString += lf + tab2 + dateFormatter.string(from: drug.startDateVar)
                simpleString += " - " + dateFormatter.string(from: drug.endDateVar!) +  " (" + drug.returnTimeOnDrug() + ")"
            } else {
                simpleString += lf + tab2 + "started: " + dateFormatter.string(from: drug.startDateVar)
                simpleString += " (since " + drug.returnTimeOnDrug() + ")"
            }

            simpleString += lf + tab2 + "\(drug.countTaken())"

            if drug.effectiveness != nil {
                simpleString += lf + tab2 + "Benefit: " + drug.effectiveness!
            }
            
            if (drug.sideEffectsVar?.count)! > 0 {
                var seString = String()
                for se in drug.sideEffectsVar! {
                    seString += se + ", "
                }
                simpleString += lf + tab2 + "Side effects: " + seString
            }
            
            let headerText = NSAttributedString(
                string: simpleString,
                attributes: [NSFontAttributeName: bodyFont]
            )
            
            if drug.notes != nil {
                simpleString = lf + tab2 + "Personal notes: " + drug.notes! + lf
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
            save()
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
                    ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 8", showInVC: self, systemError: error, errorInfo: "error fetching earliest selected event date in EventsDataController: \(error)")
                }
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
//            nextViewController.drugDictionary = drugDictionary
            
            if segue.identifier == "editDrug" {
                if let indexPath = sender {
                    // if creating new drug don't pass anything and a new will be generated in nextTVC
                    nextViewController.drugFromList = drugList.object(at: indexPath as! IndexPath)
                }
            }
        } else {
            ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 9", showInVC: self, errorInfo: "error createNew segue: destinationViewcontrolle not defined")
        }

    }
    
    @IBAction
    func returnFromNewDrugTVC(segue:UIStoryboardSegue) {
        
        save()
        tableView.reloadData()
    }
    
    
}

// MARK: - TableView DataSource

extension DrugListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sections = drugList.sections else {
            return 0
        }
        return sections.count

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sectionInfo = drugList.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "drugListCell", for: indexPath)
                as! DrugListCell
        
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }

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
                    ErrorManager.sharedInstance().errorMessage(message: "DLVC Error 10", showInVC: self, errorInfo: "error in DrugList.editRowActions.endAction - section \(indexPath.section) doesn't exist")
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
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        tableView.endUpdates()
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
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
           tableView.deleteSections(indexSet, with: .automatic)
        case .update:
            tableView.reloadSections([sectionIndex], with: .automatic)
        case .move:
            print("move section \(sectionInfo.name) at index \(sectionIndex)")
        }
    }
    
    
}

extension DrugListViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
        
    }
}

