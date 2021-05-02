//
//  SearchNewHoldingTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class SearchNewHoldingTableViewController: UITableViewController {
    
    weak var databaseController: DatabaseProtocol?
    
    var watchlist: CoreWatchlist?
    var searchResultsHoldings = [Holding]()
    
    let CELL_SEARCH_RESULT_HOLDING = "searchResultHoldingCell"
    
    let SEGUE_OWNED_HOLDING = "ownedHoldingSegue"
    
    // Indicator
    var indicator = UIActivityIndicatorView()

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
        
        // Add a loading indicator view
        self.indicator.style = UIActivityIndicatorView.Style.large
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.indicator)
        
        // Centres the loading indicator view
        NSLayoutConstraint.activate([
            self.indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            self.indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
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
        
        holdingCell.textLabel?.text = "\(holding.ticker ?? "[?]").\(holding.exchange ?? "[?]")"
        holdingCell.detailTextLabel?.text = holding.instrument
        
        return holdingCell
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ownedWatchlist = self.watchlist?.owned {
            if !ownedWatchlist {
                let holding = self.searchResultsHoldings[tableView.indexPathForSelectedRow!.row]
                let _ = databaseController?.addCoreHoldingToCoreWatchlist(ticker: holding.ticker!, coreWatchlist: self.watchlist!)
                databaseController?.saveChanges()
                
                navigationController?.popViewController(animated: true)
                
                return false
            }
        }
        
        return true
    }
    
    /// Transfers the name, instructions and ingredients of the selected meal to the CreateMealTableViewController when the user travels there
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /*
        if segue.identifier == "searchMealSegue" {
            // Define meal from cell being selected
            // SOURCE: https://stackoverflow.com/questions/44706806/how-do-i-use-prepare-segue-with-tableview-cell
            // AUTHOR: GetSwifty
            let meal = self.shownMeals[tableView.indexPathForSelectedRow!.row]
            
            // Define the destination ViewController to assign its properties
            let destination = segue.destination as! CreateMealTableViewController
            
            // Assign properties to the destination ViewController
            destination.mealName = meal.name ?? ""
            destination.mealInstructions = meal.instructions ?? ""
            destination.mealIngredients = meal.ingredients ?? []
        }
        */
    }

    func requestSearchTickerWebData(searchText: String) {
        // https://api.twelvedata.com/symbol_search?symbol=NDQ&source=docs
        
        // Form URL from different components
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/symbol_search"
        requestURLComponents.queryItems = [
            URLQueryItem(
                name: "symbol",
                value: searchText
            ),
            URLQueryItem(
                name: "source",
                value: "docs"
            )
        ]
        
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
            
            // If we have recieved an error message
            if let error = error {
                print(error)
                return
            }
            
            // Parse data
            do {
                let decoder = JSONDecoder()
                let tickerSearchResponse = try decoder.decode(TickerSearchResults.self, from: data!)
                
                for holding in tickerSearchResponse.data {
                    self.searchResultsHoldings.append(
                        Holding(
                            ticker: holding.symbol,
                            instrument: holding.instrument_name,
                            exchange: holding.exchange,
                            currency: holding.currency
                        )
                    )
                }
                
                DispatchQueue.main.async {
                    // Notify user if no results were found
                    if self.searchResultsHoldings.count == 0 {
                        Popup.displayPopup(title: "No Results", message: "No results matched \"\(searchText)\".", viewController: self)
                    }
                    
                    // Shows new empty meal button, and any recipes found
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
