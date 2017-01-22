//
//  GraphScoreChoserCell.swift
//  Alogea
//
//  Created by mikeMBP on 22/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class GraphScoreChoserCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
//    var delegate: GraphScoreChoser!
    var indexPath: IndexPath!
    var originalText: String!
    var tableView: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    public func configure(text: String?, placeHolder: String?) {
        textField.text = text
        textField.placeholder = placeHolder
        
        textField.accessibilityValue = text
        textField.accessibilityLabel = placeHolder
        
    }
    
//    func setDelegate(delegate: GraphScoreChoser, indexPath: IndexPath, tableView: UITableView) {
//        self.delegate = delegate
//        self.indexPath = indexPath
//        self.tableView = tableView
//    }
    
    func activeTextField() {
        textField.isEnabled = true
        textField.becomeFirstResponder()
    }
}

extension GraphScoreChoserCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.sizeToFit()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("end text editing")
        if textField.text?.characters.last == " " {
            textField.text!.remove(at: textField.text!.index(before: textField.text!.endIndex))
        }
        // ensure unique score name is entered
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "" {
            textField.isEnabled = false
            // create new RecordType and make this the selectedScore
            // redraw GraphScoreChoser section to show new row including new empty row
        } else {
            // no entry - revert cell back to show + button and disable textField
        }
    }
}
