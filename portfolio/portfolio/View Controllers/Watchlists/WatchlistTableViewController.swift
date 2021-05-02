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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        // Sets title to watchlist name
        self.title = self.shownWatchlist?.name
    }
    
    // https://stackoverflow.com/questions/25921623/how-to-reload-tableview-from-another-view-controller-in-swift
    @objc func loadList(notification: NSNotification){
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

}
