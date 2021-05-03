//
//  WatchlistsTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class WatchlistsTableViewController: UITableViewController {
    
    var shownWatchlists: [CoreWatchlist] = []
    
    var listenerType = ListenerType.watchlist
    weak var databaseController: DatabaseProtocol?
    
    let CELL_WATCHLIST = "watchlistCell"
    
    let SEGUE_SELECT_WATCHLIST = "selectWatchlistSegue"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Sets property databaseController to reference to the databaseController
        // from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }

    /// Returns how many sections the TableView has
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: watchlists
        return 1
    }
    
    // Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        // Adds the class to the database listeners
        // (to recieve updates from the database)
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    // Calls before the view disappears on screen
    override func viewWillDisappear(_ animated: Bool) {
        // Removes the class from the database listeners
        // (to not recieve updates from the database)
        super.viewWillDisappear(animated)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let watchlist = shownWatchlists[indexPath.row]
            databaseController?.deleteCoreWatchlist(coreWatchlist: watchlist)
            databaseController?.saveChanges()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_SELECT_WATCHLIST {
            // SOURCE: https://stackoverflow.com/questions/44706806/how-do-i-use-prepare-segue-with-tableview-cell
            // AUTHOR: GetSwifty
            let watchlist = self.shownWatchlists[tableView.indexPathForSelectedRow!.row]
            let destination = segue.destination as! WatchlistTableViewController
            
            destination.shownWatchlist = watchlist
        }
    }

}

extension WatchlistsTableViewController: DatabaseListener {
    
    func onAnyWatchlistChange(change: DatabaseChange, coreWatchlists: [CoreWatchlist]) {
        self.shownWatchlists = coreWatchlists
        tableView.reloadData()
    }

}
