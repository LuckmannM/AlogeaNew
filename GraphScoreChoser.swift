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
            if InAppStore.sharedInstance().checkMultipleGraphAccess() {
                // user purchased multiple graph option
                cell.textField.text = recordTypeNames[indexPath.row]
                cell.textField.isEnabled = false
                cell.addButton.isHidden = true
                
                if recordTypeNames[indexPath.row] == selectedScore {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                
            } else {
                // option not purchased, enable only one score ([0] element
                // there may be more than on RecordTypes stored if these have been imported from other devices
                
                if recordTypeNames[indexPath.row] == UserDefaults.standard.value(forKey: "SelectedScore") as! String {
                    cell.textField.text = recordTypeNames[indexPath.row]
                    cell.textField.isEnabled = false
                    cell.addButton.isHidden = true
                    cell.accessoryType = .checkmark
                } else {
                    // non-permitted scores
                    cell.textField.textColor = UIColor.gray
                    cell.textField.text = recordTypeNames[indexPath.row]
                    cell.textField.isEnabled = false
                    cell.addButton.isHidden = true
                    cell.accessoryType = .none
                }
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
            // user selects an existing scoreType/RecordType
            
            if indexPath.row == 0 {
                // selecting 0 element or default score always possible
                UserDefaults.standard.set(recordTypeNames[indexPath.row], forKey: "SelectedScore")
                tableView.reloadSections([indexPath.section], with: .automatic)
            } else {
                // optional additional scoreTypes can only be selected if expansion purchased
                if InAppStore.sharedInstance().checkMultipleGraphAccess() {
                    UserDefaults.standard.set(recordTypeNames[indexPath.row], forKey: "SelectedScore")
                    tableView.reloadSections([indexPath.section], with: .automatic)
                } else {
                    // if not purchased display purchase offer
                    // FIXME: Add Merge RecordTypes option
                    self.dismiss(animated: true, completion: {
                        self.rootViewController.showPurchaseDialog()
                    })
                }
            }
        } else {
            // user wants to add a new RecordType
            
            // check option purchased
            if InAppStore.sharedInstance().checkMultipleGraphAccess() {
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
