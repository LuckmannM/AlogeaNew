//
//  ErrorManager.swift
//  Alogea
//
//  Created by mikeMBP on 14/02/2017.
//  Copyright © 2017 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit


class ErrorManager: NSObject {
    
    //static var alertViewOpen: Bool!
    
    class func sharedInstance() -> ErrorManager {
        return errorManager
    }

    var alertViewOpen = false
    
    func errorMessage(title: String? = nil, message: String, showInVC: UIViewController? = nil, systemError: NSError? = nil, errorInfo: String? = nil) {
        
        var presentingVC = showInVC
        var titleToUse = title
        
        if presentingVC == nil {
            if let visibleVC = (UIApplication.shared.delegate as! AppDelegate).window?.visibleViewController {
                presentingVC = visibleVC
            } else {
                print("Error in Error manager: can't find currently visible VC")
                return
            }

        }
        
        if titleToUse ==  nil {
            titleToUse = "We're really sorry\nAn error occurred!"
        }
        
        if alertViewOpen {
// *** accumulate incoming messages and gather log
            print("incoming error while alertView open________")
            print("message \(message)")
            print("systemError: \(systemError)")
            print("errorInfo: \(errorInfo)")
            print()
            return
        } else {
            self.alertViewOpen = true
        }
        let alertController = UIAlertController(title: titleToUse, message: message, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
            self.alertViewOpen = false
        }))
        
        // Present Alert Controller
            presentingVC!.present(alertController, animated: true, completion: nil)
        
        //temporary for debugging
        print("ERROR________")
        print("systemError: \(systemError)")
        print("errorInfo: \(errorInfo)")
        
    }
    

}

let errorManager = ErrorManager()
