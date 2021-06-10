//
//  SearchNewHoldingTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class SearchNewHoldingTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    // Cell identifiers
    private let CELL_SEARCH_RESULT_HOLDING = "searchResultHoldingCell"
    
    // Segue identifiers
    private let SEGUE_OWNED_HOLDING = "ownedHoldingSegue"
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Loading indicator
    private var indicator = UIActivityIndicatorView()
    
    // Other properties
    public var watchlist: CoreWatchlist?
    private var searchResultsHoldings = [Holding]()
    
    // MARK: - Methods

    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController
        // from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Creates search object
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Symbols/Instruments"
        navigationItem.searchController = searchController
        
        // Ensure search is always visible
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Set up the loading indicator view
        SharedFunction.setUpLoadingIndicator(indicator: self.indicator, view: self.view)
    }
    
    /// Returns how many sections the TableView has
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: list of holdings from search
        return 1
    }

    /// Returns the number of rows in any given section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResultsHoldings.count
    }
    
    /// Creates the cells and contents of the TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_SEARCH_RESULT_HOLDING, for: indexPath)
        let holding = self.searchResultsHoldings[indexPath.row]
        
        // Text
        if holding.instrumentType == "Digital Currency" {
            holdingCell.textLabel?.text = "\(holding.ticker ?? Constant.NO_VALUE_FOUND) (\(holding.exchange ?? Constant.NO_VALUE_FOUND))"
            holdingCell.detailTextLabel?.text = "Cryptocurrency"
        }
        else {
            holdingCell.textLabel?.text = "\(holding.ticker ?? Constant.NO_VALUE_FOUND).\(holding.exchange ?? Constant.NO_VALUE_FOUND)"
            holdingCell.detailTextLabel?.text = holding.instrument
        }
        
        // Fonts
        holdingCell.textLabel?.font = CustomFont.setBody2Font()
        holdingCell.detailTextLabel?.font = CustomFont.setDetailFont()
        
        return holdingCell
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    /// Cancels segue being executed if duplicate holding or if watchlist isn't "Owned" (hence no need to add purchases)
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        let holding = self.searchResultsHoldings[tableView.indexPathForSelectedRow!.row]
        
        // Stop user from adding a duplicate holding
        let watchlistHoldings = self.watchlist?.holdings?.allObjects as! [CoreHolding]
        for watchlistHolding in watchlistHoldings {
            if watchlistHolding.ticker == holding.ticker! {
                Popup.displayPopup(title: "Duplicate Holding", message: "Watchlist \"\(self.watchlist?.name ?? Constant.ERROR_LABEL)\" already contains \(holding.ticker!).", viewController: self)
                return false
            }
        }
        
        // Stop user from adding purchase data for an unowned holding
        if let ownedWatchlist = self.watchlist?.owned {
            if !ownedWatchlist {
                // Add holding to watchlist in Core Data in the process
                let _ = databaseController?.addCoreHoldingToCoreWatchlist(ticker: holding.ticker!, currency: holding.currency!, coreWatchlist: self.watchlist!)
                databaseController?.saveChanges()
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadHoldings"), object: nil)
                
                navigationController?.popViewController(animated: true)
                
                return false
            }
        }
        
        return true
    }
    
    /// Assign properties to destination
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.SEGUE_OWNED_HOLDING {
            // If the user selects a watchlist, and is segued to add purchase data to it
            
            let destination = segue.destination as! NewHoldingPurchaseViewController
            let holding = self.searchResultsHoldings[tableView.indexPathForSelectedRow!.row]
            
            // Needs access to watchlist and holding to create coreHolding and add it to the watchlist
            destination.watchlist = self.watchlist
            destination.holding = holding
        }
    }

    func requestSearchTickerWebData(searchText: String) {
        // Generate URL from components
        let requestURLComponents = Algorithm.getSearchRequestURLComponents(searchText: searchText)
        
        // Ensure URL is valid
        guard let requestURL = requestURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        // Occurs on a new thread
        let task = URLSession.shared.dataTask(with: requestURL) {
            (data, response, error) in
            
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            // Parse data
            do {
                let decoder = JSONDecoder()
                let tickerSearchResponse = try decoder.decode(TickerSearchResults.self, from: data!)
                
                for holding in tickerSearchResponse.data {
                    if holding.instrument_type == "Digital Currency" || Constant.OTHER_SUPPORTED_EXCHANGES.contains(holding.exchange) {
                        self.searchResultsHoldings.append(
                            Holding(
                                ticker: holding.symbol,
                                instrument: holding.instrument_name,
                                exchange: holding.exchange,
                                currency: holding.currency,
                                instrumentType: holding.instrument_type
                            )
                        )
                    }
                }
                
                DispatchQueue.main.async {
                    // Notify user if no results were found
                    if self.searchResultsHoldings.count == 0 {
                        Popup.displayPopup(title: "No Results", message: "No results matched \"\(searchText)\".", viewController: self)
                    }
                    
                    // Update table to show results
                    self.tableView.reloadData()
                }
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }

}

// MARK: - Search Extension

extension SearchNewHoldingTableViewController: UISearchBarDelegate {
    
    /// Calls when the user clicks "search" on the keyboard
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            // Clear previously searched meals
            self.searchResultsHoldings.removeAll()
            tableView.reloadData()
            
            // Stops all existing tasks to avoid background download
            URLSession.shared.invalidateAndCancel()
            
            // Feedback is provided, and data is requested
            indicator.startAnimating()
            self.requestSearchTickerWebData(searchText: searchText)
        }
    }
    
}
