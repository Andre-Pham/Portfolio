//
//  WatchlistTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class WatchlistTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    // Cell identifiers
    private let CELL_HOLDING = "holdingCell"
    private let CELL_RENAME = "renameCell"
    
    // Section identifiers
    private let SECTION_HOLDING = 0
    private let SECTION_RENAME = 1
    
    // Segue identifiers
    private let SEGUE_ADD_HOLDING = "addHoldingSegue"
    private let SEGUE_PURCHASES = "holdingPurchasesSegue"
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Other properties
    public var coreWatchlist: CoreWatchlist?
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Adds an observer so that other pages can call reloadTableView to refresh the page
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableview), name: NSNotification.Name(rawValue: "reloadHoldings"), object: nil)
        
        // Sets title to watchlist name
        self.title = self.coreWatchlist?.name
    }
    
    // SOURCE: https://stackoverflow.com/questions/25921623/how-to-reload-tableview-from-another-view-controller-in-swift
    // AUTHOR: Sebasitan - https://stackoverflow.com/users/673526/sebastian
    /// Allows other pages to refresh the contents of this page
    @objc func reloadTableview(notification: NSNotification){
        self.tableView.reloadData()
    }

    /// Returns how many sections the TableView has
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: holdings in watchlist
        // Section 1: rename watchlist
        return 2
    }
    
    /// Returns the number of rows in any given section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Every time table view needs to know how many rows, also updates label to notify if empty
        SharedFunction.notifyIfTableViewEmpty(message: "No Holdings", isEmpty: self.coreWatchlist?.holdings?.count == 0, tableView: self.tableView)
        
        switch section {
        case self.SECTION_HOLDING:
            return self.coreWatchlist?.holdings?.count ?? 0
        case self.SECTION_RENAME:
            return 1
        default:
            return 0
        }
    }
    
    /// Creates the cells and contents of the TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == self.SECTION_HOLDING {
            let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
            
            var holdings = self.coreWatchlist?.holdings?.allObjects as! [CoreHolding]
            Algorithm.arrangeCoreHoldingsAlphabetically(&holdings)
            let holding = holdings[indexPath.row]
            
            holdingCell.textLabel?.text = holding.ticker
            
            // Add accessory if holding is owned
            if let watchlistIsOwned = self.coreWatchlist?.owned, watchlistIsOwned {
                holdingCell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }
            
            return holdingCell
        }
        else {
            // indexPath.section == self.SECTION_RENAME
            
            let renameCell = tableView.dequeueReusableCell(withIdentifier: CELL_RENAME, for: indexPath)
            
            renameCell.textLabel?.text = "Rename Watchlist"
            
            return renameCell
        }
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Holdings can be deleted
        return true
    }
    
    // SOURCE: https://developer.apple.com/forums/thread/131056
    // AUTHOR: Claude31 - https://developer.apple.com/forums/profile/Claude31
    /// Adds extra actions on the cell when swiped left
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Only holdings have actions
        if indexPath.section != self.SECTION_HOLDING {
            return UISwipeActionsConfiguration(actions: [])
        }
        
        var holdings = self.coreWatchlist?.holdings?.allObjects as! [CoreHolding]
        Algorithm.arrangeCoreHoldingsAlphabetically(&holdings)
        let holding = holdings[indexPath.row]
        
        // Delete action - deletes the watchlist
        let delete = UIContextualAction(style: .destructive, title: "delete") {
            (action, view, completion) in
        
            self.databaseController?.deleteCoreHoldingFromCoreWatchlist(coreHolding: holding, coreWatchlist: self.coreWatchlist!)
            self.databaseController?.saveChanges()
            
            tableView.reloadData()
            
            completion(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        
        // Add actions to the cells
        let swipeActions = UISwipeActionsConfiguration(actions: [delete])
        swipeActions.performsFirstActionWithFullSwipe = false
        
        return swipeActions
    }
    
    /// Calls when a segue is triggered
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if identifier == SEGUE_PURCHASES {
            // If the watchlist isn't owned, the holding can't have purchases added to it, so no segue is triggered
            if let ownedWatchlist = self.coreWatchlist?.owned {
                return ownedWatchlist
            }
        }
        
        return true
    }
    
    /// Assigns properties of destination ViewControllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.SEGUE_ADD_HOLDING {
            // User selected "Add Holding"
            
            let destination = segue.destination as! SearchNewHoldingTableViewController
            // So watchlist can have the holding added to it
            destination.watchlist = self.coreWatchlist
        }
        else if segue.identifier == self.SEGUE_PURCHASES {
            // User selected holding
            
            let destination = segue.destination as! AllHoldingPurchasesTableViewController
            // Holding is provided to load its purchases
            let holdings = self.coreWatchlist?.holdings?.allObjects as! [CoreHolding]
            let holding = holdings[tableView.indexPathForSelectedRow!.row]
            destination.coreHolding = holding
        }
    }
    
    /// If the rename cell is selected, creates a popup to retrieve a new name from the user
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_RENAME {
            self.displayRenameWatchlistPopup()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// A popup that prompts the user for a new name for the watchlist
    func displayRenameWatchlistPopup() {
        // SOURCE: https://medium.com/swift-india/uialertcontroller-in-swift-22f3c5b1dd68
        // AUTHOR: Balaji Malliswamy - https://medium.com/@blahji
        
        // Define alert
        let alertController = UIAlertController(
            title: "Rename Watchlist",
            message: "Enter the new name below.",
            preferredStyle: .alert
        )
        // Add "done" button
        alertController.addAction(
            UIAlertAction(title: "Done", style: .default) { (_) in
                if let textField = alertController.textFields?.first, let textInput = textField.text {
                    // After the user selects "done"
                    let trimmedTextInput = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Validation
                    if trimmedTextInput == "" {
                        Popup.displayPopup(title: "No Name Provided", message: "You must enter a name with at least one character.", viewController: self)
                        return
                    }
                    
                    self.coreWatchlist?.name = trimmedTextInput
                    self.title = trimmedTextInput
                    self.databaseController?.saveChanges()
                }
            }
        )
        // Add "cancel" button
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        )
        // Add text field
        alertController.addTextField {
            (textField) in textField.placeholder = "New Name"
        }
        // Display popup
        self.present(alertController, animated: true, completion: nil)
    }

}
