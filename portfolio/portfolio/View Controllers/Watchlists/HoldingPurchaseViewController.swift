//
//  HoldingPurchaseViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class HoldingPurchaseViewController: UIViewController {
    
    var purchaseToEdit: CorePurchase? = nil
    var holding: CoreHolding?
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var sharesTextField: UITextField!
    @IBOutlet weak var purchaseDatePicker: UIDatePicker!
    
    // Labels
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        self.title = self.holding?.ticker
        self.purchaseDatePicker.maximumDate = Date()
        
        // Label fonts
        self.priceLabel.font = CustomFont.setSubtitle2Font()
        self.sharesLabel.font = CustomFont.setSubtitle2Font()
        self.dateLabel.font = CustomFont.setSubtitle2Font()
        
        if let purchaseToEdit = self.purchaseToEdit {
            self.priceTextField.text = String(purchaseToEdit.price)
            self.sharesTextField.text = String(purchaseToEdit.shares)
            self.purchaseDatePicker.date = purchaseToEdit.date!
        }
    }
    
    @IBAction func saveBarButtonPressed(_ sender: Any) {
        // https://stackoverflow.com/questions/36861732/convert-string-to-date-in-swift
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateTextInput = formatter.string(from: purchaseDatePicker.date)
        let date = formatter.date(from: dateTextInput)
        
        if let price = Double(self.priceTextField.text!), let shares = Double(self.sharesTextField.text!), let date = date {
            // Validate
            var valid = true
            var errorMessage = ""
            if price <= 0 {
                valid = false
                errorMessage.append("The purchase price")
            }
            if shares <= 0 {
                if !valid {
                    errorMessage.append(" and the number of shares")
                }
                else {
                    errorMessage.append("The number of shares")
                }
                valid = false
            }
            if !valid {
                Popup.displayPopup(title: "Invalid Entries", message: errorMessage+" must be positive. Ensure your entries are valid and try again.", viewController: self)
                return
            }
            
            if let purchaseToEdit = self.purchaseToEdit {
                databaseController?.deleteCorePurchaseFromCoreHolding(corePurchase: purchaseToEdit, coreHolding: self.holding!)
            }
            let _ = databaseController?.addCorePurchaseToCoreHolding(shares: shares, date: date, price: price, coreHolding: self.holding!)
            databaseController?.saveChanges()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadPurchases"), object: nil)

            navigationController?.popViewController(animated: true)
        }
    }
    
}
