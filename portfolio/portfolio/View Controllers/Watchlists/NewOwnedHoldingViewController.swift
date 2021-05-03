//
//  NewOwnedHoldingViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class NewOwnedHoldingViewController: UIViewController {
    
    var watchlist: CoreWatchlist?
    var holding: Holding?
    
    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var sharesTextField: UITextField!
    @IBOutlet weak var purchaseDatePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        self.title = self.holding?.ticker
    }
    
    @IBAction func saveBarButtonPressed(_ sender: Any) {
        // https://stackoverflow.com/questions/36861732/convert-string-to-date-in-swift
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateTextInput = formatter.string(from: purchaseDatePicker.date)
        let date = formatter.date(from: dateTextInput)
        
        if let price = Double(self.priceTextField.text!), let shares = Double(self.sharesTextField.text!), let date = date {
            let newCoreHolding = databaseController?.addCoreHoldingToCoreWatchlist(ticker: self.holding?.ticker ?? "[?]", currency: self.holding?.currency ?? "[?]", coreWatchlist: self.watchlist!)
            let _ = databaseController?.addCorePurchaseToCoreHolding(shares: shares, date: date, price: price, coreHolding: newCoreHolding!)
            databaseController?.saveChanges()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadHoldings"), object: nil)

            // https://stackoverflow.com/questions/30003814/how-can-i-pop-specific-view-controller-in-swift
            for controller in self.navigationController!.viewControllers as Array {
                if controller.isKind(of: WatchlistTableViewController.self) {
                    self.navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
        }
    }
    
}
