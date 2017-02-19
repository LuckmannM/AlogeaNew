//
//  SubstanceAndClassPopUp.swift
//  Alogea
//
//  Created by mikeMBP on 22/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class SubstanceAndClassPopUp: UITableViewController {
    
    var theDrug: DrugEpisode!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ingredientCell", for: indexPath)
        
        if indexPath.section == 0 {
            (cell.contentView.viewWithTag(10) as! UITextField).text = theDrug.substancesString()
        } else {
            (cell.contentView.viewWithTag(10) as! UITextField).text = theDrug.classesString()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Active substances"
        } else {
            return "Medication Class"
        }
    }
}
