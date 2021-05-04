//
//  WatchlistTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class WatchlistTableViewController: UITableViewController {
    
    var shownWatchlist: CoreWatchlist?
    
    let CELL_HOLDING = "holdingCell"
    let CELL_RENAME = "renameCell"
    
    let SECTION_HOLDING = 0
    let SECTION_RENAME = 1
    
    let SEGUE_ADD_HOLDING = "addHoldingSegue"
    let SEGUE_PURCHASES = "holdingPurchasesSegue"
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableview), name: NSNotification.Name(rawValue: "reloadHoldings"), object: nil)
        
        // Sets title to watchlist name
        self.title = self.shownWatchlist?.name
    }
    
    // https://stackoverflow.com/questions/25921623/how-to-reload-tableview-from-another-view-controller-in-swift
    @objc func reloadTableview(notification: NSNotification){
        //load data here
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
        switch section {
        case self.SECTION_HOLDING:
            return self.shownWatchlist?.holdings?.count ?? 0
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
            let holdings = self.shownWatchlist?.holdings?.allObjects as! [CoreHolding]
            let holding = holdings[indexPath.row]
            
            holdingCell.textLabel?.text = holding.ticker
            
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
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if identifier == SEGUE_PURCHASES {
            if let ownedWatchlist = self.shownWatchlist?.owned {
                return ownedWatchlist
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_ADD_HOLDING {
            let destination = segue.destination as! SearchNewHoldingTableViewController
            destination.watchlist = self.shownWatchlist
        }
        else if segue.identifier == SEGUE_PURCHASES {
            let destination = segue.destination as! HoldingPurchasesTableViewController
            let holdings = self.shownWatchlist?.holdings?.allObjects as! [CoreHolding]
            let holding = holdings[tableView.indexPathForSelectedRow!.row]
            destination.coreHolding = holding
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_RENAME {
            self.displayRenameWatchlistPopup()
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
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
                    
                    self.shownWatchlist?.name = trimmedTextInput
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
