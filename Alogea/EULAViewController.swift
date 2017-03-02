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
        
        //textView.isHidden = true
        textView.text = touHeader + purposeAlimitations + dataSecurity + privacy + eulaText

        updateConfirmationLabel()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        textView.scrollRangeToVisible(NSMakeRange(0,0))
//        textView.isHidden = false
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
        
        if UserDefaults.standard.bool(forKey: "TOUAccepted") == false {
            (UIApplication.shared.delegate as! AppDelegate).applicationWillTerminate((UIApplication.shared))
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
    
    func showTOUMessage() {
        
        // this presents the same on iPads and iPhones
        let termsOfUseDialog = UIAlertController(title: "Important", message: "To protect you data your device must be protected with a pass code. You must obtain professional clinical advice about using medicines; this App is not a substitute for medical advice.", preferredStyle: .alert)
        
        let acknowledgeAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: { (UIAlertController)
            -> Void in
        })
        
        
        termsOfUseDialog.addAction(acknowledgeAction)
        
        self.present(termsOfUseDialog, animated: true, completion: nil)
    }
    
    let purposeAlimitations = "I. PURPOSE AND LIMITATIONS OF APP USE\nAlogea® is intended as a personal support tool to assist you in monitoring and managing your day-to-day pain and pain-related problems.\nYou understand that Alogea® it NOT intended to guide or give advice on medical treatment or diagnosis. You must obtain qualified medical advice before taking, or refraining from taking, medicines or actions on the basis of the content of this App.\n\nYou understand that use of the App must not replace or delay professional clinical advice; you must follow this advice and the instructions of your treating clinician.\nYOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT YOU MUST CONSULT YOUR RESPONSIBLE CLINICIAN / PRESCRIBER BEFORE MAKING CHANGES TO YOUR MEDICATION. YOU MUST NOT DEVIATE FROM THE RECOMMENDED WAY OF TAKING MEDICINES AS A CONSEQUENCE OF USING THIS APP WITHOUT PRIOR DISCUSSION WITH YOUR RESPONSIBLE CLINICIAN/ PRESCRIBER.\n\n"
    let dataSecurity = "II. DATA SECURITY\nFor your data to be encrypted by standard iOS® encryption tools and stored safely you must protect all devices Alogea® is installed on with suitable passcode protection. IF YOU DO NOT USE DEVICE PASSCODE PROTECTION YOUR DATA IS NOT ENCRYPTED AND CAN BE READ BY OTHERS.\n\nTo reduce the risk of data loss, and the consequences of data corruption, it is STRONGLY RECOMMENDED TO MAKE BACKUPS regularly in the ‘Settings’ section. Loss of, or corruption of data, is subject to liability limitations in section e. of the GENERAL END USER LICENSE AGREEMENT.\n\n"
    let privacy = "III. PRIVACY\n\nWe may collecy and process data about you: informationton you give us when downloading Alogea, purchasing Alogea expansion in the InApp Store, technical infomration about your device and related software, hardware and peripherals, and details of your use of Alogea and related services"
    
    let touHeader = "TERMS OF USE\n\n"
    
    let eulaText = "GENERAL END USER LICENSE AGREEMENT"

}
