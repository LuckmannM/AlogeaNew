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
    lazy var drugList: NSFetchedResultsController<DrugEpisode> = {
        let request = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        request.sortDescriptors = [NSSortDescriptor(key: "isCurrent", ascending: true), NSSortDescriptor(key: "startDate", ascending: false)]
        
        let dL = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "isCurrent", cacheName: nil)
        dL.delegate = self
        
        return dL
        
    }()

    var persistentStoreCoordinatorChangesObserver:NotificationCenter? {
        didSet {
            oldValue?.removeObserver(self, name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: stack.coordinator)
            persistentStoreCoordinatorChangesObserver?.addObserver(self, selector: #selector(persistentStoreCoordinatorDidChangeStores(notification:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: stack.coordinator)
        }
    }

    // MARK: - View functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // stack.updateContextWithUbiquitousChangesObserver = true
        drugCurrentStatusUpdate()
        fetchDrugList()
        
        if drugList.fetchedObjects != nil {
            actionButton.isEnabled = true
        } else {
            actionButton.isEnabled = false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // persistentStoreCoordinatorChangesObserver = NotificationCenter.default
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        
        // the next hides the search bar until it is dragged down by user
        tableView.contentOffset = CGPoint(x: 0.0, y: self.tableView.tableHeaderView!.frame.size.height)
        

        drugDictionary = DrugDictionary.sharedInstance()
        inAppStore = InAppStore.sharedInstance()
        
//        tableView.register(DrugListCell.self, forCellReuseIdentifier: cellIdentifier)
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
                print("\(aDrug.name) status updated to \(aDrug.isCurrent)")
                do {
                    try aDrug.managedObjectContext!.save()
                    print("\(aDrug.name) individually saved to moc")
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
            cell.backgroundColor = UIColor.lightGray
        } else {
            cell.backgroundColor = UIColor.white
        }
        
        switch indexPath.section {
        case 0: // CURRENT DRUGS
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
            cell.startDateLabel.text = ""
            if aDrug.endDate != nil {
                cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug()), until \(aDrug.endDateString())"
            } else {
                cell.otherInfoLabel.text = "Since \(aDrug.returnTimeOnDrug())"
            }
            //                print("effectiveness of selected drug is \((drugList.objectAtIndexPath(indexPath) as! DrugEpisode).effectivenessStore)")
            cell.ratingImageForButton(effect: aDrug.returnEffect(), sideEffects: aDrug.returnSideEffect())
            cell.ratingButton.addTarget(self, action: #selector(popUpRatingView(sender:)), for: .touchUpInside)
            cell.ratingButton.tag = indexPath.row
            cell.ratingButton.isEnabled = true
            
            
        case 1: // DISCONTINUED DRUGS

            if inAppStore.checkDrugFormularyAccess() == true {
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.nameLabel.text = aDrug.returnName() // using 'name' results in blank for returning drugs when using searchController druglistFRC
                cell.startDateLabel.text = aDrug.returnTimeOnDrug()
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
                cell.startDateLabel.text = ""
                cell.otherInfoLabel.text = "Full version required for details"
            }

        default:
            print("error in DrugListVC - section number wrong: \(indexPath.section)")
        }
        
    }
    
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
        popUpController!.permittedArrowDirections = .any
        popUpController!.sourceView = sender
        popUpController?.sourceRect = sender.bounds
        popUpController!.delegate = self
        
        // do this AFTER setting up the PopoverPresentationController or it won't work as popUP on iPhone!
        self.present(ratingViewController, animated: true, completion: nil)

    }
    
    func save() {
        // save to mOC only; changes to mOC will be spotted by (persistentStoreCoordinatorChangesObserver)?
        // by the NSFetchedResultsController (fetchedSettings). This observes the mOC/stack and reports changes to the
        // NSFetchedResultsController DElegate methods at the bottom (pSCDidChangeStores)
        // this triggers pSCDidChangeStores func which carries out re-fetch and re-load
        
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
            
            print("returning to graphViewContainer from presenting print dialog")
            
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
    
    
    // MARK: - UIPopoverPresentationController delegate methods
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        

        if let presentedController = popoverPresentationController.presentedViewController as? DrugRating {
            
            let indexPath = IndexPath(row: presentedController.sendingButtonInRow, section: 0)
            let selectedDrug = drugList.object(at: indexPath)
            
            let cell = tableView.cellForRow(at: indexPath) as! DrugListCell
            cell.ratingImageForButton(effect: presentedController.effectSelected, sideEffects: presentedController.sideEffectSelected)
            // tableView.reloadRows(at: [indexPath], with: .automatic)
            
            selectedDrug.effectivenessVar = presentedController.effectSelected
            selectedDrug.sideEffectsVar = [presentedController.sideEffectSelected]
            selectedDrug.saveEffectAndSideEffects()
            
            save()
        } else {
            // return from deleteAlertController on iPad only
            
        }

        
    }
    
    // MARK: - Navigation
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        

        if let nextViewController = segue.destination as? NewDrug {
            nextViewController.rootViewController = self
            nextViewController.drugDictionary = drugDictionary
            
            if segue.identifier == "editDrug" {
                if let indexPath = sender {
                    // if creating new drug don't pass anything and a new will be generated in nextTVC
                    nextViewController.drugFromList = drugList.object(at: indexPath as! IndexPath)
                }
            } else if segue.identifier == "createNew" {
                
                // check that IAP has been made
                // otherwise alert that only one drug can be active and offer link to IAPStore
                
            } else {
                print("error createNew segue: destinationViewcontrolle not defined")
            }
        }

    }
    
    @IBAction
    func returnFromNewDrugTVC(segue:UIStoryboardSegue) {
        
        
        save()
        
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
        
        if let sections = drugList.sections {
            return sections.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sectionInfo = drugList.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "drugListCell", for: indexPath)
                as! DrugListCell
        
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
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
                
                let drugToStop = self.drugList.object(at: indexPath) 
                drugToStop.setTheEndDate(date: Date())
                drugToStop.storeObjectForEnding() // essential for FRC to change display
                drugToStop.cancelNotifications()
                self.save()
                //self.fetchDrugList()
                
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
        
        if indexPath.section == 0 { return [endAction, deleteAction] }
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
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! DrugListCell!
            configureCell(cell: cell!, indexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
        
        if drugList.fetchedObjects != nil {
            actionButton.isEnabled = true
        } else {
            actionButton.isEnabled = false
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        let indexSet = NSIndexSet(index: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(indexSet as IndexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet as IndexSet, with: .automatic)
        default:
            break
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

