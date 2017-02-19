//
//  DrugRating.swift
//  Alogea
//
//  Created by mikeMBP on 15/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData

class DrugRating: UITableViewController {
    
    var effectSelected: String!
    var sideEffectSelected: String!
    var sendingButtonInRow: Int!
    //    var theDrug: DrugEpisode!
    
    @IBOutlet weak var notesTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(doneButtonAction))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func doneButtonAction() {
//        //        theDrug.saveEffectAndSideEffects()
//        
//    }
    
    func setCheckMarks() {
        
        var indexPath: IndexPath!
        
        switch effectSelected {
        case "good":
            indexPath = IndexPath(row: 0, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        case "moderate":
            indexPath = IndexPath(row: 1, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        case "minimal":
            indexPath = IndexPath(row: 2, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        case "none":
            indexPath = IndexPath(row: 3, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        default:
            indexPath = IndexPath(row: 0, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            indexPath = IndexPath(row: 1, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            indexPath = IndexPath(row: 2, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            indexPath = IndexPath(row: 3, section: 0)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
        
        switch sideEffectSelected {
        case "none":
            indexPath = IndexPath(row: 0, section: 1)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        case "moderate":
            indexPath = IndexPath(row: 1, section: 1)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        case "strong":
            indexPath = IndexPath(row: 2, section: 1)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        default:
            indexPath = IndexPath(row: 0, section: 1)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            indexPath = IndexPath(row: 1, section: 1)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            indexPath = IndexPath(row: 2, section: 1)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
        
        tableView.reloadData()
        
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath == IndexPath(row: 0, section: 2) {
            notesTextView.frame.size = CGSize(width: self.view.frame.width - 30, height: 200)
            return 210
        }
        else {
            return 44
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.section == 0 { // effect ratings
            for i in 0 ..< 4 {
                let newPath = IndexPath(row: i, section: 0)
                self.tableView.cellForRow(at: newPath)?.accessoryType = UITableViewCellAccessoryType.none
            }
            
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            switch indexPath.row {
            case 0:
                effectSelected = "good"
            case 1:
                effectSelected = "moderate"
            case 2:
                effectSelected = "minimal"
            case 3:
                effectSelected = "none"
            default:
                effectSelected = "in evaluation"
            }
        } else if indexPath.section == 1 { // side effect ratings
            for i in 0 ..< 3 {
                let newPath = IndexPath(row: i, section: 1)
                self.tableView.cellForRow(at: newPath)?.accessoryType = UITableViewCellAccessoryType.none
            }
            
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            switch indexPath.row {
            case 0:
                sideEffectSelected = "none"
            case 1:
                sideEffectSelected = "moderate"
            case 2:
                sideEffectSelected = "strong"
            default:
                sideEffectSelected = "in evaluation"
            }
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return "Effect rating"
        } else {
            return "Side effects rating"
        }
    }
    
    
}
