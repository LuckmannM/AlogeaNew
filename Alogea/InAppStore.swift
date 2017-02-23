//
//  InAppStore.swift
//  Alogea
//
//  Created by mikeMBP on 13/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//


// Class object initialised by AppDelegate and shared by IAPStoreViewC
// loads locally stored productID strings from InAppProductsIP.plist file
// checks with productRequest wether these are available in AppStore
// and returnd product infomration from the AppStore to be displayed in IAPStoreVC
// IAPStoreVC generates payment requests, that the InAppStore class processes, and
// stores purchases of products as their full productID in Userdefaults locally
// and shortened productID in iCloud KeyValueStorage
// these are checked at Class init on product load to enable associated functionaility


import UIKit
import Foundation
import StoreKit
import SystemConfiguration

public typealias ProductIdentifier = String

public let InAppStorePurchaseNotification = "InAppStorePurchaseNotification"
public let InAppStoreProductRequestCompleted = "InAppStoreProductRequestCompleted"

class InAppStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver  {
    
    class func sharedInstance() -> InAppStore {
        return InAppStoreGlobal
    }
    
    var productRequest: SKProductsRequest!
    var products: [SKProduct]?
    var availableProductIDs = Set<ProductIdentifier>()
    var purchasedProductIDs = Set<ProductIdentifier>()
    
    var callingViewController: UIViewController?
    
    var progressIndicator: UIActivityIndicatorView!
    
    override init() {
        super.init()
        
        // retrieve productIDs from local .plist file
        // alternatives are retrieving from server, which enables adding IAP without re-submitting App updates
        
        let localProductIDs = NSArray(contentsOf: Bundle.main.url(forResource: "InAppProductIDs", withExtension: "plist")!) as![String]
        
        for productIdentifier in localProductIDs {
            availableProductIDs.insert(productIdentifier)
            let purchasedLocal = UserDefaults.standard.bool(forKey: productIdentifier)
            let purchasediCloud = NSUbiquitousKeyValueStore.default().bool(forKey: shortNameForProductID(productIdentifier: productIdentifier)!)
            if purchasedLocal || purchasediCloud {
                purchasedProductIDs.insert(productIdentifier)
                print("already purchased: \(shortNameForProductID(productIdentifier: productIdentifier))")
            }
        }
        
        productRequest = SKProductsRequest(productIdentifiers: availableProductIDs)
        productRequest.delegate = self
        productRequest.start()
        SKPaymentQueue.default().add(self)
        
        progressIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        progressIndicator.isHidden = true
    }
    
    func refreshProductRequest() {
        if productRequest == nil {
            productRequest = SKProductsRequest(productIdentifiers: availableProductIDs)
            productRequest.delegate = self
            productRequest.start()
        }
    }
    
    func shortNameForProductID(productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
    
    // MARK: - purchase enquiries
    
    
    func checkDrugFormularyAccess() -> Bool {
               
        var qualifiesForAccess = false
        
        for productID in purchasedProductIDs {
            if productID.contains("FullVersion") || productID.contains("UnlimitedMedicines") {
                qualifiesForAccess = true
            }
        }
        
        return false
        // *** DEBUG, reinstate this return qualifiesForAccess
    }
    
    func checkMultipleGraphAccess() -> Bool {
        
        var qualifiesForAccess = false
        
        for productID in purchasedProductIDs {
            if productID.contains("FullVersion") || productID.contains("UnlimitedGraphs") {
                qualifiesForAccess = true
            }
        }
        return qualifiesForAccess
    }
    
    
    //MARK: - SKProductRequest Delegate protocol method
    @objc func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        products = response.products
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: InAppStoreProductRequestCompleted), object: nil)
        
        for invalidID in response.invalidProductIdentifiers {
            ErrorManager.sharedInstance().errorMessage(message: "IAPStore Error 1", errorInfo: "invalid product ID in InAppStore: \(invalidID)")
            // handle invalid product identifiers
        }
        productRequest = nil
    }
    
    // SKProductRequest Delegate protocol method
    private func request(request: SKRequest, didFailWithError error: NSError) {
        ErrorManager.sharedInstance().errorMessage(message: "IAPStore Error 2", systemError: error)
        productRequest = nil
    }
    
    func createPurchaseRequest(product: SKProduct, fromViewController: UIViewController?) {
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        
        if fromViewController != nil {
            callingViewController = fromViewController!
            progressIndicator.frame = CGRect(x: (callingViewController?.view.frame.size.width)! / 2 - 100 / 2, y: (callingViewController?.view.frame.size.height)! / 2 - 100 / 2, width: 100, height: 100)
                callingViewController!.view.addSubview(progressIndicator)
            progressIndicator.startAnimating()
        }
        
        
        SKPaymentQueue.default().add(payment)
    }
    
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    
    //MARK: -  SKPaymentTransactionProtocol Delegate protocol method
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions  {
            switch transaction.transactionState {
            case .purchasing:
                showTransactionAsInProgress(transaction: transaction)
            case .purchased:
                transactionCompleted(transaction: transaction)
            case .failed:
                transactionFailed(transaction: transaction)
            case .deferred:
                showTransactionAsInProgress(transaction: transaction)
            case .restored:
                transactionRestored(transaction: transaction)
            }
        }
    }
    
    func showTransactionAsInProgress(transaction: SKPaymentTransaction) {
        
        
        switch transaction.transactionState {
        case .deferred:
            progressIndicator.stopAnimating()
            deferredMessage()
        default:
            print("transaction in progress...")
            // show some progress indicator
            // spinner
        }
    }
    
    func transactionCompleted(transaction: SKPaymentTransaction) {
        
        progressIndicator.stopAnimating()
        progressIndicator.removeFromSuperview()
        
        let userdefaults = UserDefaults.standard
        userdefaults.set(true, forKey: transaction.payment.productIdentifier)
        let iCloudAppStatus = NSUbiquitousKeyValueStore.default()
        iCloudAppStatus.set(true, forKey: shortNameForProductID(productIdentifier: transaction.payment.productIdentifier)!)
        userdefaults.synchronize()
        iCloudAppStatus.synchronize()
        purchasedProductIDs.insert(transaction.payment.productIdentifier)
        manageCompletedTransaction(transaction: transaction)
    }
    
    func transactionFailed(transaction: SKPaymentTransaction) {
        
        progressIndicator.stopAnimating()
        if transaction.transactionState == SKPaymentTransactionState.failed {
            
            SKPaymentQueue.default().finishTransaction(transaction)
            
            if let transactionError = transaction.error as? NSError {
                if transactionError.code == SKError.paymentCancelled.rawValue {
                    return
                }
            }
            
//            if callingViewController != nil {
//                let alert = UIAlertController(title: "AppStore transaction error", message: transaction.error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
//                
//                let dismiss = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: {
//                    (alert) -> Void in
//                })
//                
//                alert.addAction(dismiss)
//                
//                if UIDevice().userInterfaceIdiom == .pad {
//                    let popUpController = alert.popoverPresentationController
//                    popUpController!.permittedArrowDirections = .up
//                    popUpController?.sourceView = callingViewController!.view
//                }
//                
//                
//                callingViewController!.present(alert, animated: true, completion: nil)
//                
//            }
//            else {
                errorMessage(message: "AppStore transaction failed", errorInfo: "Transaction error: \(transaction.error!.localizedDescription)")
//            }
        }
    }
    
    func transactionRestored(transaction: SKPaymentTransaction) {
        let userdefaults = UserDefaults.standard
        userdefaults.set(true, forKey: (transaction.original?.payment.productIdentifier)!)
        let iCloudAppStatus = NSUbiquitousKeyValueStore.default()
        iCloudAppStatus.set(true, forKey: shortNameForProductID(productIdentifier: (transaction.original?.payment.productIdentifier)!)!)
        userdefaults.synchronize()
        iCloudAppStatus.synchronize()
        manageCompletedTransaction(transaction: transaction)
    }
    
    func manageCompletedTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: InAppStorePurchaseNotification), object: transaction.payment.productIdentifier)
    }
    
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                zeroSockAddress in
                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)

    }
    //** DEBUG
    func checkPurchasePersistence(transaction: SKPaymentTransaction) {
        
        print("QA Check - PURCHASE PERSISTENCE LOCAL AND ICLOUD -----------")
        let purchasedLocal = UserDefaults.standard.bool(forKey: transaction.payment.productIdentifier)
        print("local storage of FullVersion purchase is \(purchasedLocal)")
        
        let purchasediCloud = NSUbiquitousKeyValueStore.default().bool(forKey: transaction.payment.productIdentifier)
        print("iCloud storage of FullVersion purchase is \(purchasediCloud)")
        
    }
    
    // MARK: - Message Displays
    
    func deferredMessage() {
        
        
        guard let visibleVC = (UIApplication.shared.delegate as! AppDelegate).window?.visibleViewController else {
            return
        }
        
        let title = "Thank you!"
        let message = "Please continue to use Alogea while your purchase is pending approval from your family delegate."
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
            
        }))
        
        // Present Alert Controller
        visibleVC.present(alertController, animated: true, completion: nil)
    }
    
    
    func errorMessage(message: String, showInVC: UIViewController? = nil, systemError: NSError? = nil, errorInfo: String? = nil) {
        
        var presentingVC = showInVC
        
        if presentingVC == nil {
            if let visibleVC = (UIApplication.shared.delegate as! AppDelegate).window?.visibleViewController {
                presentingVC = visibleVC
            } else {
                print("Error in Error manager: can't find currently visible VC")
                return
            }
            
        }
        
        let title = "App Store error"
        let message = "A transaction problem has occurred"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in

        }))
        
        // Present Alert Controller
        presentingVC!.present(alertController, animated: true, completion: nil)
        //*** consider sending an email to support with description
        // do somehting with NSError
        
        
        //temporary for debugging
        
        print("ERROR________")
        print("systemError: \(systemError)")
        print("errorInfo: \(errorInfo)")
        
    }
}

let InAppStoreGlobal = InAppStore()

