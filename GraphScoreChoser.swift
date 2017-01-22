//
//  GraphScoreChoser.swift
//  Alogea
//
//  Created by mikeMBP on 21/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class GraphScoreChoser: UITableViewController {
    
    var selectedScore: String {
        return UserDefaults.standard.value(forKey: "SelectedScore") as! String
    }
    
    var recordTypeNames: [String] {
        return RecordTypesController.sharedInstance().recordTypeNames
    }

    let titleTag = 10
    let buttonTag = 40
    
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

        return RecordTypesController.sharedInstance().recordTypeNames.count
        // or RecordTypesController. sharedInstance().allTypes.fetchedObjects?.count ?? 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "graphViewChoserCell", for: indexPath) as! GraphScoreChoserCell

        if indexPath.row < recordTypeNames.count {
            cell.textField.text = recordTypeNames[indexPath.row]
            cell.textField.isEnabled = false
            cell.addButton.isHidden = true
            cell.addButton.isEnabled = false
            
            if recordTypeNames[indexPath.row] == selectedScore {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            // active add button here dn when pressed active textField in didSelectRow
            cell.addButton.isHidden = false
            cell.addButton.isEnabled = true
            cell.addButton.addTarget(self, action: #selector(GraphScoreChoserCell.activeTextField), for: .touchUpInside)
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // select and deselect checkmark and change selectedScore in UserDefaults
        
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < recordTypeNames.count {
            UserDefaults.standard.set(recordTypeNames[indexPath.row], forKey: "SelectedScore")
            tableView.reloadSections([indexPath.section], with: .automatic)
        } else {
            // hide + button and activate textField for entry of new scoreEvent type
        }

    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
