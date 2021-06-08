//
//  HoldingPurchaseViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class HoldingPurchaseViewController: UIViewController {
    
    // MARK: - Properties
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Other properties
    public var purchaseToEdit: CorePurchase? = nil // nil for new purchases being added
    public var holding: CoreHolding?
    
    // MARK: - Outlets
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var sharesTextField: UITextField!
    @IBOutlet weak var purchaseDatePicker: UIDatePicker!
    
    // Labels
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()

        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // Set title to ticker
        self.title = self.holding?.ticker
        // Restrict date to current date
        self.purchaseDatePicker.maximumDate = Date()
        
        // Label fonts
        self.priceLabel.font = CustomFont.setSubtitle2Font()
        self.sharesLabel.font = CustomFont.setSubtitle2Font()
        self.dateLabel.font = CustomFont.setSubtitle2Font()
        
        // If a purchase is being edited (hence purchaseToEdit != nil)
        if let purchaseToEdit = self.purchaseToEdit {
            // Set default entries
            self.priceTextField.text = String(purchaseToEdit.price)
            self.sharesTextField.text = String(purchaseToEdit.shares)
            self.purchaseDatePicker.date = purchaseToEdit.date!
        }
    }
    
    /// Calls when save button is pressed
    @IBAction func saveBarButtonPressed(_ sender: Any) {
        // SOURCE: https://stackoverflow.com/questions/36861732/convert-string-to-date-in-swift
        // AUTHOR: vadian - https://stackoverflow.com/users/5044042/vadian
        // Retrieve date from date picker
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateTextInput = formatter.string(from: purchaseDatePicker.date)
        let date = formatter.date(from: dateTextInput)
        
        if let price = Double(self.priceTextField.text!), let shares = Double(self.sharesTextField.text!), let date = date {
            // Validate entries
            if !SharedFunction.purchaseEntriesIsValid(price: price, shares: shares, viewController: self) {
                // Popup is taken care of by function
                return
            }
            
            // Add purchase to Core Data
            if let purchaseToEdit = self.purchaseToEdit {
                databaseController?.deleteCorePurchaseFromCoreHolding(corePurchase: purchaseToEdit, coreHolding: self.holding!)
            }
            let _ = databaseController?.addCorePurchaseToCoreHolding(shares: shares, date: date, price: price, coreHolding: self.holding!)
            databaseController?.saveChanges()
            
            // Refresh purchases page
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadPurchases"), object: nil)

            navigationController?.popViewController(animated: true)
        }
        else {
            Popup.displayPopup(title: "Invalid Entries", message: "An error occurred from your entries. Please ensure numbers were entered, and try again.", viewController: self)
        }
    }
    
}
