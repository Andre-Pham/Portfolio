//
//  DashboardViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    var shownWatchlist: Watchlist?
    let CELL_HOLDING = "holdingCell"
    
    @IBOutlet weak var holdingsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TESTING
        let holding1 = Holding(ticker: "TEST", dates: ["TEST_DATE"], prices: [100], currentPrice: 100)
        let holding2 = Holding(ticker: "TEST2", dates: ["TEST_DATE2"], prices: [200], currentPrice: 200)
        
        self.shownWatchlist = Watchlist(name: "TEST_NAME", owned: false)
        self.shownWatchlist?.holdings?.append(holding1)
        self.shownWatchlist?.holdings?.append(holding2)
        // TESTING END

        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownWatchlist?.holdings?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
        let holding = self.shownWatchlist?.holdings?[indexPath.row]
        
        holdingCell.textLabel?.text = holding?.ticker
        holdingCell.detailTextLabel?.text = holding?.ticker
        
        return holdingCell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}
