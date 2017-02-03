//
//  EventRect PopUp.swift
//  Alogea
//
//  Created by mikeMBP on 03/02/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class EventPopUp: UIViewController {

 
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func labelTexts(title: String, date: String, text:String) {
        titleLabel.text = title
        titleLabel.sizeToFit()
        titleLabel.isHidden = false
        
        dateLabel.text = date
        dateLabel.sizeToFit()
        dateLabel.isHidden = false
        
        textView.text = text
        textView.isHidden = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
