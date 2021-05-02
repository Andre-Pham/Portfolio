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
    
    let SEGUE_EDIT_PURCHASE = "editPurchaseSegue"
    let SEGUE_NEW_PURCHASE = "newPurchaseSegue"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableview), name: NSNotification.Name(rawValue: "reloadPurchases"), object: nil)

        self.title = self.coreHolding?.ticker
    }
    
    // https://stackoverflow.com/questions/25921623/how-to-reload-tableview-from-another-view-controller-in-swift
    @objc func reloadTableview(notification: NSNotification){
        //load data here
        self.tableView.reloadData()
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
    
    /// Transfers the name, instructions and ingredients of the selected meal to the CreateMealTableViewController when the user travels there
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! HoldingPurchaseViewController
        destination.holding = self.coreHolding
        
        if segue.identifier == SEGUE_EDIT_PURCHASE {
            let purchases = self.coreHolding?.purchases?.allObjects as! [CorePurchase]
            destination.purchaseToEdit = purchases[tableView.indexPathForSelectedRow!.row]
        }
    }

}
