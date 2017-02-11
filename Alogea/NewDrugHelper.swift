//
//  NewDrugHelper.swift
//  Alogea
//
//  Created by mikeMBP on 12/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit

class NewDrugHelper: NSObject {
    
    
    var allCellArray = [[[String]]]()
    var visibleCellArrayString = String()
    var visibleCellArray = [[[String]]]() {
        didSet {
            visibleCellArrayString = ""
            for section in visibleCellArray {
                for row in section {
                    visibleCellArrayString += row[0]
                }
            }
            
        }
    }
    
    
    func initHelper(regularly: Bool) {
        
        setUpCellArray(regularly: regularly)
    }
    
    func numberOfSections() -> Int {
        return visibleCellArray.count
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        return visibleCellArray[section].count
    }
    
    func insertNonPickerCellRow(forIndexPath: IndexPath) {
        
        let pathInAllCellArray: IndexPath = pathForCellInAllCellArray(cellType: returnAnyCellType(forIndexPath: forIndexPath as IndexPath))
        let cellTypeToInsert = allCellArray[pathInAllCellArray.section][pathInAllCellArray.row]
        
        var cellNeighborInVisibleArrayPath: IndexPath
        var sectionArray = visibleCellArray[forIndexPath.section]
        if forIndexPath.row > 0 {
            let cellTypeRowAbove = allCellArray[pathInAllCellArray.section][pathInAllCellArray.row-1][0]
            cellNeighborInVisibleArrayPath = returnPathForCellTypeInVisibleArray(cellType: cellTypeRowAbove)
            sectionArray.insert(cellTypeToInsert, at: cellNeighborInVisibleArrayPath.row+1)
        } else {
            let cellTypeRowBelow = allCellArray[pathInAllCellArray.section][pathInAllCellArray.row+1][0]
            cellNeighborInVisibleArrayPath = returnPathForCellTypeInVisibleArray(cellType: cellTypeRowBelow)
            sectionArray.insert(cellTypeToInsert, at: cellNeighborInVisibleArrayPath.row-1)
        }
        
        visibleCellArray.remove(at: forIndexPath.section)
        visibleCellArray.insert(sectionArray, at: forIndexPath.section)
        
    }
    
    func insertVisibleRow(forIndexPath: IndexPath) {
        
        let pathInAllCellArray: IndexPath = pathForCellInAllCellArray(cellType: returnVisibleCellTypeAtPath(indexPath: forIndexPath))
        let cellTypeToInsert = allCellArray[pathInAllCellArray.section][pathInAllCellArray.row+1]
        
        var sectionArray = visibleCellArray[forIndexPath.section]
        sectionArray.insert(cellTypeToInsert, at: forIndexPath.row+1)
        visibleCellArray.remove(at: forIndexPath.section)
        visibleCellArray.insert(sectionArray, at: forIndexPath.section)
        
    }
    
    func removeVisibleRow(row: Int, inSection: Int) {
        
        var array = visibleCellArray[inSection]
        array.remove(at: row)
        visibleCellArray[inSection] = array
        
    }
    
    func returnVisibleCellTypeAtPath(indexPath: IndexPath) -> String {
        
        return visibleCellArray[indexPath.section][indexPath.row][0]
        
    }
    
    func returnVisibleCellArrayAtPath(indexPath: IndexPath) -> [String] {
        
        return visibleCellArray[indexPath.section][indexPath.row]
        
    }
    
    
    func pathForCellInAllCellArray(cellType:String) -> IndexPath {
        
        var path = IndexPath()
        
        var i = 0
        var j = 0
        
        for section in allCellArray {
            for row in section {
                if row[0] == cellType {
                    path = IndexPath(row: j, section: i)
                    break
                }
                j += 1
            }
            j=0
            i += 1
        }
        return path
    }
    
    func returnPathForCellTypeInVisibleArray(cellType:String) -> IndexPath {
        
        var path = IndexPath()
        
        var i = 0
        var j = 0
        
        for section in visibleCellArray {
            for row in section {
                if row[0] == cellType {
                    path = IndexPath(row: j, section: i)
                    break
                }
                j += 1
            }
            j=0
            i += 1
        }
        return path
    }
    
    func returnAnyCellType(forIndexPath: IndexPath) -> String {
        
        return allCellArray[forIndexPath.section][forIndexPath.row][0]
    }
    
    func pickerViewVisible(name: String) -> Bool {
        
        if visibleCellArrayString.contains(name) {
            return true
        }
        else {return false}
    }
    
    
    func setUpCellArray(regularly: Bool) {
        
        // Cell Prototypes
        let titleOnlyCell = "titleOnlyCell"
        let emptyCell = "emptyCell"
        let titleAndDetailCell = "titleAndDetailCell"
        let titleAndSwitchCell = "titleAndSwitchCell"
        let segmentControlCell = "segmentControlCell"
        let textViewCell = "textViewCell"
        
        // SECTION 0
        let nameCell = ["nameCell",titleOnlyCell]
        let namePickerCell = ["namePickerCell", emptyCell]
        
        // SECTION 1
        let dosesCell = ["dosesCell", titleAndDetailCell]
        let doseUnitCell = ["doseUnitCell", segmentControlCell]
        
        // SECTION 2
        let startDateCell = ["startDateCell", titleAndDetailCell]
        let startDatePickerCell = ["startDatePickerCell", emptyCell]
        let endDateCell = ["endDateCell", titleAndDetailCell]
        let endDatePickerCell = ["endDatePickerCell", emptyCell]
        let frequencyCell = ["frequencyCell", titleAndDetailCell]
        let frequencyPickerCell = ["frequencyPickerCell", emptyCell]
        let regularityCell = ["regularityCell", titleAndSwitchCell]
        let timesCell = ["timesCell", titleAndDetailCell]
        let timesPickerCell = ["timesPickerCell",emptyCell]
        
        // SECTION 3
        let notesCell = ["notesCell", textViewCell]
        
        allCellArray = [
            [
                nameCell,
                namePickerCell
            ],
            [
                dosesCell,
                doseUnitCell
                
            ],
            [
                startDateCell,
                startDatePickerCell,
                endDateCell,
                endDatePickerCell,
                frequencyCell,
                frequencyPickerCell,
                regularityCell,
                timesCell,
                timesPickerCell
            ],
            [
                notesCell
            ]
        ]
        
        if regularly {
            visibleCellArray = [[
                    nameCell
                ],
                [
                    dosesCell,
                    doseUnitCell
                ],
                [
                    startDateCell,
                    endDateCell,
                    frequencyCell,
                    regularityCell,
                    timesCell
                ],
                [
                    notesCell
                ]
            ]
        } else {
            visibleCellArray = [[
                    nameCell
                ],
                [
                    dosesCell,
                    doseUnitCell
                ],
                [
                    startDateCell,
                    endDateCell,
                    frequencyCell,
                    regularityCell
                ],
                [
                    notesCell
                ]
            ]
        }
        
    }
    
}
