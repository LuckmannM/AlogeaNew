//
//  GraphScoreChoser.swift
//  Alogea
//
//  Created by mikeMBP on 21/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class GraphScoreChoser: UITableViewController {
    
    var rootViewController: MainViewController!
    
    var selectedScore: String {
        return UserDefaults.standard.value(forKey: "SelectedScore") as! String
    }
    
    var recordTypeNames: [String] {
        return RecordTypesController.sharedInstance().recordTypeNames
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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

        return RecordTypesController.sharedInstance().recordTypeNames.count + 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "graphViewChoserCell", for: indexPath) as! GraphScoreChoserCell
        cell.setDelegate(delegate: self, indexPath: indexPath, tableView: self.tableView)

        if indexPath.row < recordTypeNames.count {
            cell.textField.text = recordTypeNames[indexPath.row]
            cell.textField.isEnabled = false
            cell.addButton.isHidden = true
            
            if recordTypeNames[indexPath.row] == selectedScore {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            // active add button here dn when pressed active textField in didSelectRow
            cell.addButton.isHidden = false
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // select and deselect checkmark and change selectedScore in UserDefaults
        
        let cell = tableView.cellForRow(at: indexPath) as! GraphScoreChoserCell
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < recordTypeNames.count {
            UserDefaults.standard.set(recordTypeNames[indexPath.row], forKey: "SelectedScore")
            tableView.reloadSections([indexPath.section], with: .automatic)
        } else {
            
            // check option purchased
            // *** return to true!
            if !InAppStore.sharedInstance().checkMultipleGraphAccess() {
                cell.activateTextField()
                cell.addButton.isHidden = true
            } else {
                self.dismiss(animated: true, completion: {
                    self.rootViewController.showPurchaseDialog()
                })
            }
        }

    }

}
