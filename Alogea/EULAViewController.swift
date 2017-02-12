//
//  EULAViewController.swift
//  Alogea
//
//  Created by mikeMBP on 12/02/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import UIKit

class EULAViewController: UIViewController {

    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var confirmationLabel: UILabel!
    
    var rootViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateConfirmationLabel()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateConfirmationLabel() {
        
        if UserDefaults.standard.value(forKey: "TOUAccepted") != nil {
            var confirmed = String()
            
            if UserDefaults.standard.bool(forKey: "TOUAccepted") == true {
                confirmed = "accepted"
            } else {
                confirmed = "declined"
            }
            
            confirmationLabel.text = "You " + confirmed + " these Terms of Use on \(UserDefaults.standard.value(forKey: "TOUAcceptanceDate")!)"
            
        } else {
            confirmationLabel.text = "You must accept the Terms Of Use in order to use this App"
            confirmationLabel.sizeToFit()
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func declineAction(_ sender: UIButton) {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter
        }()

        UserDefaults.standard.set(false, forKey: "TOUAccepted")
        UserDefaults.standard.set(dateFormatter.string(from: Date()), forKey: "TOUAcceptanceDate")
        updateConfirmationLabel()
    }

    @IBAction func acceptAction(_ sender: Any) {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            return formatter
        }()
        
        UserDefaults.standard.set(true, forKey: "TOUAccepted")
        UserDefaults.standard.set(dateFormatter.string(from: Date()), forKey: "TOUAcceptanceDate")
        updateConfirmationLabel()
        self.dismiss(animated: true, completion: {
            self.removeFromParentViewController()
        })
    }
}
