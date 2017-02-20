//
//  StoreView.swift
//  Alogea
//
//  Created by mikeMBP on 17/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class StoreView: UITableViewController {
    
    var inAppStore = InAppStore.sharedInstance()
    var defaultMessage1 = String()
    var defaultMessage2 = String()
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        return formatter
    }()
    
    var rootView: UIViewController!
        
    // MARK: - ViewController methods
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.tabBarController?.tabBar.isHidden = true
        
        if inAppStore.products == nil {
            inAppStore.refreshProductRequest()
        }
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
    
        NotificationCenter.default.addObserver(self, selector: #selector(productPurchaseComplete(notification:)), name: NSNotification.Name(rawValue: InAppStorePurchaseNotification), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(productRequestComplete(notification:)), name: NSNotification.Name(rawValue: InAppStoreProductRequestCompleted), object: nil)
        
        if inAppStore.isConnectedToNetwork() == false {
            noNetworkAlert()
        }
        
        tableView.allowsSelection = false
        inAppStore.callingViewController = self
}
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        inAppStore.callingViewController = nil
    }
    
    func noNetworkAlert() {
        
        let alert = UIAlertController(title: "No internet connection", message: "There is currently no network access\nPlease return to in-app purchase option when a network connection is available", preferredStyle: UIAlertControllerStyle.alert)
        
        let goBackAction = UIAlertAction(title: "Back", style: .default, handler: {
            (alert) -> Void in
            self.navigationController!.popToRootViewController(animated: true)
        })
        
        let stayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {
            (alert) -> Void in
        })
        
        alert.addAction(goBackAction)
        alert.addAction(stayAction)
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = alert.popoverPresentationController
            popUpController!.permittedArrowDirections = .up
            popUpController?.sourceView = self.view
        }
        

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func buyButtonAction(sender: UIButton) {
        
        self.inAppStore.createPurchaseRequest(product: self.inAppStore.products![sender.tag], fromViewController: self)
        
    }

    
    func productRequestComplete(notification: Notification) {
        
    }
    
    func productPurchaseComplete(notification: Notification) {
        successMessage()
        tableView.reloadData()
    }


    
    //MARK: - TableView methods

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

            return 1
}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if inAppStore.products != nil && inAppStore.canMakePayments() {
            return inAppStore.products!.count
        } else {
            if inAppStore.isConnectedToNetwork() {
                defaultMessage1 = "We are sorry!"
                defaultMessage2 = "Expansions are currently unavailable. Please try again later"
            } else {
                defaultMessage1 = "No network connection"
                defaultMessage2 = "can't connect to App Store. Please try again when connected to the internet"
            }
            return 1
        }
}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath) as! StoreViewCell

        if inAppStore.products != nil {
            let product = inAppStore.products![indexPath.row]
            let text = NSAttributedString(
                string: product.localizedTitle,
                attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 28)!,
                             NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                             NSUnderlineColorAttributeName: UIColor.black
                ]
            )
            cell.titleLabel.attributedText = text
            
            cell.descriptionLabel.text = product.localizedDescription
           
            if inAppStore.purchasedProductIDs.contains(product.productIdentifier) {
                cell.accessoryType = .checkmark
                cell.buyButton.isEnabled = false
                cell.buyButton.setTitle("purchased", for: .normal)
            }
            else {
                priceFormatter.locale = product.priceLocale
                let title = NSAttributedString(
                    string: priceFormatter.string(from: product.price)!,
                    attributes: [NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 24)!,
                                 NSForegroundColorAttributeName: UIColor.white]
                )

                cell.buyButton.setAttributedTitle(title, for: .normal)
                cell.buyButton.tag = indexPath.row
                cell.accessoryType = .none
                cell.buyButton.isEnabled = true
            }
            
            switch indexPath.row {
                case 0:
                    cell.backgroundImageView.image = UIImage(named:"NoLimitsBG")
                case 1:
                    cell.backgroundImageView.image = UIImage(named:"UnlimitedSymptomsBG")
                case 2:
                    cell.backgroundImageView.image = UIImage(named:"UnlimitedMedicinesBG")
                default:
                cell.backgroundImageView = nil
            }
            
        } else {
            
            cell.titleLabel.text = defaultMessage1
            cell.descriptionLabel.text = defaultMessage2
            cell.titleLabel.font = UIFont(name: "AvenirNext-Regular", size: 28)
            cell.buyButton.setTitle("£-.-", for: .normal)
            cell.buyButton.isEnabled = false
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height / 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "The Alogea Store"
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        var textSize: CGFloat = 24
        header.textLabel?.font = UIFont(name: "AvenirNext-Bold", size: textSize)
        header.textLabel?.sizeToFit()
        
        while header.textLabel!.frame.height > view.frame.height {
            textSize = textSize - 2
            header.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: textSize)
            header.textLabel?.sizeToFit()
        }
        
        header.textLabel?.textColor = ColorScheme.sharedInstance().lightGray
    }
    
    func successMessage() {
        
        
        let title = "Thank you!"
        let message = "Purchased completed successfully. This will be valid for all your devices"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
            
        }))
        
        // Present Alert Controller
        self.present(alertController, animated: true, completion: nil)
    }
    

}

class DescriptionLabel: UILabel {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.preferredMaxLayoutWidth =  self.frame.width
    }
    
    
}
