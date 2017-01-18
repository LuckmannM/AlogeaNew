//
//  TextInputCell.swift
//  Alogea
//
//  Created by mikeMBP on 18/01/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class TextInputCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var SubLabel: UILabel!
    
    var delegate: EventTypeSettings!
    var indexPath: IndexPath!
    
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
    
    func setDelegate(delegate: EventTypeSettings, indexPath: IndexPath) {
        self.delegate = delegate
        self.indexPath = indexPath
    }
}

extension TextInputCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.sizeToFit()
        print("beginning text editing")
    }
    
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            
            textField.resignFirstResponder()
            return false
        }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("end text editing")
        if textField.text != nil {
            delegate.receiveNewText(text: textField.text!, fromCellAtPath: indexPath)
        }
        
        return true
    }
}
