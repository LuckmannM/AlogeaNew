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
    
    struct ErrorLogBook {
        var location = String()
        var systemMessage: NSError?
        var errorInfo = String()
        
        mutating func create(location: String, systemError: NSError? = nil, errorInfo: String) {
            self.location = location
            self.errorInfo = errorInfo
            if systemError != nil {
                self.systemMessage = NSError()
                self.systemMessage = systemError
            }
        }
    }
    
    var errorLogBook: [ErrorLogBook]?
    
    class func sharedInstance() -> ErrorManager {
        return errorManager
    }

    var alertViewOpen = false
    
    func errorMessage(title: String? = nil, message: String, showInVC: UIViewController? = nil, systemError: NSError? = nil, errorInfo: String? = nil) {
        
        var presentingVC = showInVC
        var titleToUse = title
        
        addErrorLog(errorLocation: message, systemError: systemError, errorInfo: errorInfo)

        
        if presentingVC == nil {
            if let visibleVC = (UIApplication.shared.delegate as! AppDelegate).window?.visibleViewController {
                presentingVC = visibleVC
            } else {
                addErrorLog(errorLocation: "ErrorManager", errorInfo: "can't find currently visible VC")
                return
            }

        }
        
        if titleToUse ==  nil {
            titleToUse = "We're really sorry\nAn error occurred!"
        }
        
        if alertViewOpen {
            print("incoming error while alertView open")
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
        
    }
    
    func addErrorLog(errorLocation: String, systemError: NSError? = nil, errorInfo: String?) {
        
        // gathering error messages without displaying to the user
        // this may be useful if other alert is already displayed e.g. in Backups if Backup fails at the end
        // think about persisting these in a lof file
        
        errorLogBook = [ErrorLogBook]()
        
        let newError = ErrorLogBook.init(location: errorLocation, systemMessage: systemError, errorInfo: errorInfo ?? "no info")
        errorLogBook?.append(newError)
        print("Error LogBook entry added...")
        print("   location:\(newError.location)")
        print("   system message:\(newError.systemMessage ?? nil)")
        print("   erroInfo:\(newError.errorInfo)")
    }

}

let errorManager = ErrorManager()
