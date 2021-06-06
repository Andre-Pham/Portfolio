//
//  NewOwnedHoldingViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class NewOwnedHoldingViewController: UIViewController {
    
    // MARK: - Properties
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Other properties
    var watchlist: CoreWatchlist?
    var holding: Holding?
    
    // MARK: - Outlets
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var sharesTextField: UITextField!
    @IBOutlet weak var purchaseDatePicker: UIDatePicker!
    
    // Labels
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    // MARK: - Methods
    
    /// Calls on page load
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
    }
    
    // MARK: - Actions
    
    /// When the save button is pressed, creates and saves a new holding to the watchlist, with its purchase information
    @IBAction func saveBarButtonPressed(_ sender: Any) {
        // SOURCE: https://stackoverflow.com/questions/36861732/convert-string-to-date-in-swift
        // AUTHOR: vadian - https://stackoverflow.com/users/5044042/vadian
        // Retrieve date from date picker
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
            
            // Create and save the new holding to core data
            let newCoreHolding = databaseController?.addCoreHoldingToCoreWatchlist(ticker: self.holding?.ticker ?? "[?]", currency: self.holding?.currency ?? "[?]", coreWatchlist: self.watchlist!)
            // Create and save the new purchase to the holding in core data
            let _ = databaseController?.addCorePurchaseToCoreHolding(shares: shares, date: date, price: price, coreHolding: newCoreHolding!)
            databaseController?.saveChanges()
            
            // Reload watchlist page with holdings to show new holding
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadHoldings"), object: nil)

            // SOURCE: https://stackoverflow.com/questions/30003814/how-can-i-pop-specific-view-controller-in-swift
            // AUTHOR: Mohit - https://stackoverflow.com/users/3152985/mohit
            // Return back to the watchlist page with the holdings
            for controller in self.navigationController!.viewControllers as Array {
                if controller.isKind(of: WatchlistTableViewController.self) {
                    self.navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
        }
        else {
            Popup.displayPopup(title: "Invalid Entries", message: "An error occurred from your entries. Please ensure numbers were entered, and try again.", viewController: self)
        }
    }
    
}
