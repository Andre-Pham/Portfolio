//
//  HoldingPurchasesTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class HoldingPurchasesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    // Cell identifiers
    private let CELL_PURCHASE = "purchaseCell"
    
    // Segue identifiers
    private let SEGUE_EDIT_PURCHASE = "editPurchaseSegue"
    private let SEGUE_NEW_PURCHASE = "newPurchaseSegue"
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Other properties
    public var coreHolding: CoreHolding?
    
    // MARK: - Methods

    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Adds an observer so that other pages can call reloadTableView to refresh the page
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableview), name: NSNotification.Name(rawValue: "reloadPurchases"), object: nil)

        // Sets title to ticker
        self.title = self.coreHolding?.ticker
    }
    
    // SOURCE: https://stackoverflow.com/questions/25921623/how-to-reload-tableview-from-another-view-controller-in-swift
    // AUTHOR: Sebasitan - https://stackoverflow.com/users/673526/sebastian
    /// Allows other pages to refresh the contents of this page
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
        
        var allPurchases = self.coreHolding?.purchases?.allObjects as! [CorePurchase]
        Algorithm.arrangeCorePurchases(&allPurchases)
        let purchase = allPurchases[indexPath.row]
        
        let purchaseDate = purchase.date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        
        // Text label
        purchaseCell.textLabel?.text = formatter.string(from: purchaseDate!)
        purchaseCell.textLabel?.font = CustomFont.setBodyFont()
        
        // Detail text label
        purchaseCell.detailTextLabel?.text = "\(purchase.shares) shares at $\(purchase.price)"
        purchaseCell.detailTextLabel?.font = CustomFont.setDetailFont()
        
        return purchaseCell
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // SOURCE: https://developer.apple.com/forums/thread/131056
    // AUTHOR: Claude31 - https://developer.apple.com/forums/profile/Claude31
    /// Adds extra actions on the cell when swiped left
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var allPurchases = self.coreHolding?.purchases?.allObjects as! [CorePurchase]
        Algorithm.arrangeCorePurchases(&allPurchases)
        let purchase = allPurchases[indexPath.row]
        
        // Delete action - deletes the watchlist
        let delete = UIContextualAction(style: .destructive, title: "delete") {
            (action, view, completion) in
            
            self.databaseController?.deleteCorePurchaseFromCoreHolding(corePurchase: purchase, coreHolding: self.coreHolding!)
            self.databaseController?.saveChanges()
            
            tableView.reloadData()
            
            completion(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        
        // Add actions to the cells - if there's only one purchase, you can't remove it
        var swipeActions = UISwipeActionsConfiguration(actions: [delete])
        if self.coreHolding?.purchases?.count == 1 {
            swipeActions = UISwipeActionsConfiguration(actions: [])
        }
        swipeActions.performsFirstActionWithFullSwipe = false
        
        return swipeActions
    }
    
    /// Transfers the name, instructions and ingredients of the selected meal to the CreateMealTableViewController when the user travels there
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // You're either adding a purchase, or editing a purchase, either way the destination requires access to the holding to edit/add to
        let destination = segue.destination as! HoldingPurchaseViewController
        destination.holding = self.coreHolding
        
        if segue.identifier == self.SEGUE_EDIT_PURCHASE {
            // If you're editing an existant pruchase, destination needs to preview its data and edit it
            
            var allPurchases = self.coreHolding?.purchases?.allObjects as! [CorePurchase]
            Algorithm.arrangeCorePurchases(&allPurchases)
            destination.purchaseToEdit = allPurchases[tableView.indexPathForSelectedRow!.row]
        }
    }

}
