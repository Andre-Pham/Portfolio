//
//  WatchlistsTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class WatchlistsTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    // Constants
    let CELL_WATCHLIST = "watchlistCell"
    let SEGUE_SELECT_WATCHLIST = "selectWatchlistSegue"
    
    // Core data
    weak var databaseController: DatabaseProtocol?
    
    // Listeners
    var listenerType = ListenerType.watchlist
    
    // Other properties
    var shownWatchlists: [CoreWatchlist] = []
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }

    /// Returns how many sections the TableView has
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: watchlists
        return 1
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Adds the class to the database listeners
        // (to recieve updates from the database)
        databaseController?.addListener(listener: self)
    }
    
    /// Calls before the view disappears on screen
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Removes the class from the database listeners
        // (to not recieve updates from the database)
        databaseController?.removeListener(listener: self)
    }
    
    /// Returns the number of rows in any given section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownWatchlists.count
    }
    
    /// Creates the cells and contents of the TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: watchlists
        
        let watchlistCell = tableView.dequeueReusableCell(withIdentifier: CELL_WATCHLIST, for: indexPath)
        let watchlist = self.shownWatchlists[indexPath.row]
        
        watchlistCell.textLabel?.text = watchlist.name
        // Subtitle indicates if the watchlist is the portfolio or owned (otherwise no subtitle)
        if watchlist.isPortfolio {
            watchlistCell.detailTextLabel?.text = "Portfolio"
        }
        else if watchlist.owned {
            watchlistCell.detailTextLabel?.text = "Owned"
        }
        else {
            watchlistCell.detailTextLabel?.text = nil
        }
        
        // If the watchlist is the portfolio, add an icon to indicate it
        if watchlist.isPortfolio {
            watchlistCell.imageView?.image = UIImage(systemName: "chart.pie.fill")
        }
        else {
            watchlistCell.imageView?.image = nil
        }
        
        return watchlistCell
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Watchlists can be deleted
        return true
    }
    
    // SOURCE: https://developer.apple.com/forums/thread/131056
    // AUTHOR: Claude31 - https://developer.apple.com/forums/profile/Claude31
    /// Adds extra actions on the cell when swiped left
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let watchlist = self.shownWatchlists[indexPath.row]
        
        // Delete action - deletes the watchlist
        let delete = UIContextualAction(style: .destructive, title: "delete") {
            (action, view, completion) in
        
            self.databaseController?.deleteCoreWatchlist(coreWatchlist: watchlist)
            self.databaseController?.saveChanges()
            completion(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        
        // Portfolio action - sets the watchlist to be the user's 'portfolio'
        let setToPortfolio = UIContextualAction(style: .normal, title: "set to portfolio") {
            (action, view, completion) in
            
            self.databaseController?.reassignPortfolio(newPortfolio: watchlist)
            self.databaseController?.saveChanges()
            completion(true)
        }
        setToPortfolio.image = UIImage(systemName: "chart.pie.fill")
        setToPortfolio.backgroundColor = UIColor(red: 0.20, green: 0.48, blue: 0.97, alpha: 1.00)
        
        // Add actions to the relevant cells
        // * The user's portfolio can't be re-selected as the portfolio
        // * Watchlists that aren't owned can't be selected as the portfolio
        var swipeActions = UISwipeActionsConfiguration(actions: [delete])
        if !watchlist.isPortfolio && watchlist.owned {
            swipeActions = UISwipeActionsConfiguration(actions: [delete, setToPortfolio])
        }
        swipeActions.performsFirstActionWithFullSwipe = false
        
        return swipeActions
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_SELECT_WATCHLIST {
            // SOURCE: https://stackoverflow.com/questions/44706806/how-do-i-use-prepare-segue-with-tableview-cell
            // AUTHOR: GetSwifty - https://stackoverflow.com/users/1852164/getswifty
            // The page that shows the watchlist (WatchlistTableViewController) requires access to the watchlist
            let watchlist = self.shownWatchlists[tableView.indexPathForSelectedRow!.row]
            let destination = segue.destination as! WatchlistTableViewController
            destination.shownWatchlist = watchlist
        }
    }

}

// MARK: - DatabaseListener Extension

extension WatchlistsTableViewController: DatabaseListener {
    
    func onAnyWatchlistChange(change: DatabaseChange, coreWatchlists: [CoreWatchlist]) {
        self.shownWatchlists = coreWatchlists
        tableView.reloadData()
    }

}
