//
//  HoldingPurchasesTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class HoldingPurchasesTableViewController: UITableViewController {
    
    var coreHolding: CoreHolding?
    
    let CELL_PURCHASE = "purchaseCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.coreHolding?.ticker
    }

    /// Returns how many sections the TableView has
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: list of purchases of holding
        return 1
    }

    /// Returns the number of rows in any given section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.coreHolding?.purchases?.count ?? 0
    }
    
    /// Creates the cells and contents of the TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let purchaseCell = tableView.dequeueReusableCell(withIdentifier: CELL_PURCHASE, for: indexPath)
        let purchases = self.coreHolding?.purchases?.allObjects as! [CorePurchase]
        let purchase = purchases[indexPath.row]
        
        let purchaseDate = purchase.date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        
        purchaseCell.textLabel?.text = formatter.string(from: purchaseDate!)
        purchaseCell.detailTextLabel?.text = "\(purchase.shares) shares at $\(purchase.price)"
        
        return purchaseCell
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // CHANGE TO TRUE LATER
        return false
    }

}
