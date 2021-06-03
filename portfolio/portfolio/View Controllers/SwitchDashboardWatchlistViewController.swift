//
//  SwitchDashboardWatchlistViewController.swift
//  portfolio
//
//  Created by Andre Pham on 3/6/21.
//

import UIKit

class SwitchDashboardWatchlistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    // Constants
    let CELL_WATCHLIST = "watchlistCell"
    
    // Core data
    weak var databaseController: DatabaseProtocol?
    
    // Listeners
    var listenerType = ListenerType.watchlist
    
    // Other properties
    var shownWatchlists: [CoreWatchlist] = []
    
    var switchWatchlistDelegate: SwitchWatchlistDelegate?
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: CustomFont.setSubtitle2Font()]
        
        self.navigationBar.setTitleVerticalPositionAdjustment(CGFloat(2), for: UIBarMetrics.default)
        
        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When the user selects a row within the Table View

        self.switchWatchlistDelegate?.switchWatchlist(self.shownWatchlists[indexPath.row])

        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - TableView Methods Extension

extension SwitchDashboardWatchlistViewController {
    
    /// Returns how many sections the TableView has
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: watchlists
        return 1
    }
    
    /// Returns the number of rows in any given section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownWatchlists.count
    }
    
    /// Creates the cells and contents of the TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        watchlistCell.textLabel?.font = CustomFont.setBodyFont()
        watchlistCell.detailTextLabel?.font = CustomFont.setDetailFont()
        
        return watchlistCell
    }
    
}

// MARK: - DatabaseListener Extension

extension SwitchDashboardWatchlistViewController: DatabaseListener {
    
    func onAnyWatchlistChange(change: DatabaseChange, coreWatchlists: [CoreWatchlist]) {
        self.shownWatchlists = coreWatchlists
        tableView.reloadData()
    }

}
