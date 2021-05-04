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
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        self.title = self.holding?.ticker
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
    }
    
}
