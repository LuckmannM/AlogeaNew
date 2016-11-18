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
    var defaultMessage = String()
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        return formatter
    }()
    
    var rootView: UIViewController!
        
    // MARK: - ViewController methods
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if inAppStore.products == nil {
            inAppStore.refreshProductRequest()
        }
        
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.navigationController?.popToRootViewController(animated: true)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = UIBarButtonSystemItem.done

    
        NotificationCenter.default.addObserver(self, selector: #selector(productPurchaseComplete(notification:)), name: NSNotification.Name(rawValue: InAppStorePurchaseNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(productRequestComplete(notification:)), name: NSNotification.Name(rawValue: InAppStoreProductRequestCompleted), object: nil)
        
        if inAppStore.isConnectedToNetwork() == false {
            noNetworkAlert()
        }
}
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func noNetworkAlert() {
        
        let alert = UIAlertController(title: "No internet connection", message: "There is currently no network access. Please return to in-app purchase option when a network connection is available", preferredStyle: UIAlertControllerStyle.alert)
        
        let goBackAction = UIAlertAction(title: "Back", style: .default, handler: {
            (alert) -> Void in
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        let stayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {
            (alert) -> Void in
        })
        
        alert.addAction(goBackAction)
        alert.addAction(stayAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func buyButtonAction(sender: UIButton) {
        self.inAppStore.createPurchaseRequest(product: self.inAppStore.products![sender.tag])
        
    }

    
    func productRequestComplete(notification: Notification) {
        
    }
    
    func productPurchaseComplete(notification: Notification) {
        
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
                defaultMessage = "There are currently no products available"
            } else {
                defaultMessage = "No network connection - can't connect to the App Store"
            }
            return 1
        }
}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath) as! StoreViewCell

        if inAppStore.products != nil {
            let product = inAppStore.products![indexPath.row]
            cell.titleLabel.text = product.localizedTitle
            cell.descriptionLabel.text = product.localizedDescription
            
            if inAppStore.purchasedProductIDs.contains(product.productIdentifier) {
                //                cell.accessoryType = .Checkmark
                //                cell.accessoryView = nil
                //                cell.productPrice.text = ""
                cell.buyButton.isEnabled = false
                cell.priceLabel.text = "purchased"
            }
            else {
                priceFormatter.locale = product.priceLocale
                cell.priceLabel.text = priceFormatter.string(from: product.price)
                cell.buyButton.tag = indexPath.row
//                cell.buyButton.addTarget(self, action: #selector(InAppStoreViewController.buyButtonAction(_:)), forControlEvents: .TouchUpInside)
                cell.accessoryType = .none
            }
        } else {
            cell.titleLabel.text = defaultMessage
            cell.priceLabel.text = ""
        }
        
        cell.titleLabel.sizeToFit()
        cell.descriptionLabel.sizeToFit()
        cell.priceLabel.sizeToFit()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
