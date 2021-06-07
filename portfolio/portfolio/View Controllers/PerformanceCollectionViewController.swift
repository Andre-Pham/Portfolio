//
//  PerformanceCollectionViewController.swift
//  portfolio
//
//  Created by Andre Pham on 23/5/21.
//

// CollectionView
// SOURCE: https://stackoverflow.com/questions/31735228/how-to-make-a-simple-collection-view-with-swift
// AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch

import UIKit

private let reuseIdentifier = "Cell"

class PerformanceCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    // Constants
    let CELL_WIDE = "wideCell"
    let CELL_SINGLE = "singleCell"
    let CELL_TALL = "tallCell"
    let WIDE_CELL_RANGE = 0...0
    let SINGLE_CELL_RANGE = 1...4
    let TALL_CELL_RANGE = 5...6
    let SINGLE_CELL_TITLES = ["Most Growth", "Most Return", "Least Growth", "Least Return"]
    let TALL_CELL_TITLES = ["Winners", "Losers"]
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Loading indicators
    var indicator = UIActivityIndicatorView()
    var refreshControl = UIRefreshControl()
    
    // Other properties
    var portfolio: CoreWatchlist?
    var holdings: [Holding] = []
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Add margins to the collection
        collectionView!.contentInset = UIEdgeInsets(top: 5, left: 15, bottom: 20, right: 15)
        
        // Set up frame adn spacing for the collection
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Constant.CGF_LEADING // spacing left/right
        layout.minimumLineSpacing = Constant.CGF_LEADING // spacing up/down
        self.collectionView.frame = self.view.frame
        self.collectionView.collectionViewLayout = layout
        
        // SOURCE: https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
        // AUTHOR: Ahmad F - https://stackoverflow.com/users/5501940/ahmad-f
        // Add scroll up to refresh
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlChanged(_:)), for: .valueChanged)
        self.collectionView.refreshControl = self.refreshControl
        
        SharedFunction.setUpLoadingIndicator(indicator: self.indicator, view: self.view)
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.databaseController = appDelegate?.databaseController
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        if let portfolioAssigned = databaseController?.portfolioAssigned(), !portfolioAssigned {
            Popup.displayPopup(title: "No Portfolio", message: "This page can't display content unless you've set a portfolio with holdings. To get started go to the Watchlists page and create an \"Owned\" watchlist, and make sure to add your holdings.", viewController: self)
        }
        
        // If the user has designated a different or new watchlist to be their portfolio, refresh the page's content
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.portfolio || self.portfolio?.holdings?.count != self.holdings.count {
            self.portfolio = portfolio
            self.refresh()
        }
    }
    
    /// Calls when the user scrolls up to refresh
    @objc func refreshControlChanged(_ sender: AnyObject) {
        if !self.collectionView.isDragging {
            self.refresh()
        }
    }
    
    // SOURCE: https://stackoverflow.com/questions/22225207/uirefreshcontrol-jitters-when-pulled-down-and-held
    // AUTHOR: Devin - https://stackoverflow.com/users/968108/devin
    /// Calls when the user stops dragging, used to detect when to refresh after user scrolls up and holds
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.refreshControl.isRefreshing {
            self.refresh()
        }
    }
    
    /// Refreshes page's content
    func refresh() {
        self.holdings.removeAll()
        self.refreshControl.endRefreshing() // End before loading indicator begins
        self.generateData(unitsBackwards: 1, unit: .day, interval: "30min")
    }
    
    /// Assigns calls a request to the API which in turn loads data
    func generateData(unitsBackwards: Int, unit: Calendar.Component, interval: String) {
        // Retrieve and validate portfolio
        self.portfolio = self.databaseController?.retrievePortfolio()
        guard let portfolio = self.portfolio else {
            return
        }
        
        // Create queries for API request
        let tickers = Algorithm.getTickerQuery(portfolio)
        let previousOpenDate = Algorithm.getPreviousOpenDateQuery(unit: unit, unitsBackwards: unitsBackwards)
        
        // Calls the API which in turn provides data to the chart and labels
        SharedFunction.requestTickerWebData(
            tickers: tickers,
            startDate: previousOpenDate,
            interval: interval,
            indicator: self.indicator,
            coreWatchlist: self.portfolio,
            completion: { [weak self] result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let holdings):
                    self?.holdings = holdings
                    DispatchQueue.main.async {
                        self?.collectionView.reloadData()
                    }
                }
            }
        )
    }

    // MARK: - UICollectionViewDataSource

    /// Returns how many sections the CollectionView has
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    /// Returns how many cells given any section
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }

    /// Creates the cells and content of the CollectionView
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case WIDE_CELL_RANGE:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_WIDE, for: indexPath as IndexPath) as! WidePerformanceCollectionViewCell
            cell.backgroundColor = UIColor(named: "WhiteBlack1")
            
            let totalReturnInPercentage = Algorithm.getAverageAnnualReturnInPercentage(holdings)
            
            // Title label
            cell.titleLabel.text = "Average\nAnnual\nReturn"
            cell.titleLabel.font = CustomFont.setSubtitle2Font()
            
            // Average Annual Return label
            if totalReturnInPercentage.isNaN {
                cell.averageAnnualReturnLabel.text = Constant.DEFAULT_LABEL
                cell.averageAnnualReturnLabel.textColor = UIColor(named: "BodyText1")
            }
            else {
                cell.averageAnnualReturnLabel.text = Algorithm.getReturnInPercentageDescription(totalReturnInPercentage)
                cell.averageAnnualReturnLabel.textColor = Algorithm.getReturnColour(totalReturnInPercentage)
            }
            cell.averageAnnualReturnLabel.font = CustomFont.setFont(size: Algorithm.getAdjustedLargeFontSize(totalReturnInPercentage), style: CustomFont.LARGE_STYLE, weight: CustomFont.LARGE_WEIGHT)
            
            return cell
            
        case SINGLE_CELL_RANGE:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_SINGLE, for: indexPath as IndexPath) as! SinglePerformanceCollectionViewCell
            cell.backgroundColor = UIColor(named: "WhiteBlack1")
            
            // Title label
            cell.titleLabel.text = self.SINGLE_CELL_TITLES[indexPath.row-1]
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            // Ticker label
            cell.tickerLabel.font = CustomFont.setLarge2Font()
            
            // Total return label
            cell.totalReturnLabel.font = CustomFont.setBodyFont()
            
            // Creates parameters for the best/worst holding in terms of growth/return
            var rank = "Worst"
            if indexPath.row <= 2 {
                rank = "Best"
            }
            let returnFormat = ["Dollars", "Percentage"][indexPath.row%2]
            // Find holding according to parameters
            if let holding = Algorithm.getBestOrWorstHolding(self.holdings, Best_or_Worst: rank, Percentage_or_Dollars: returnFormat) {
                // Ticker label text
                cell.tickerLabel.text = holding.ticker
                
                // Total return label text and colour
                var returnValue: Double
                if returnFormat == "Dollars" {
                    returnValue = holding.getReturnInDollars()
                    cell.totalReturnLabel.text = Algorithm.getReturnInDollarsDescription(returnValue)
                }
                else {
                    returnValue = holding.getReturnInPercentage()
                    cell.totalReturnLabel.text = Algorithm.getReturnInPercentageDescription(returnValue)
                }
                cell.totalReturnLabel.textColor = Algorithm.getReturnColour(returnValue)
            }
            else {
                cell.tickerLabel.text = Constant.DEFAULT_LABEL
                cell.totalReturnLabel.text = Constant.DEFAULT_LABEL
            }
            
            return cell
            
        case TALL_CELL_RANGE:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TALL, for: indexPath as IndexPath) as! TallPerformanceCollectionViewCell
            cell.backgroundColor = UIColor(named: "WhiteBlack1")
            
            // Title label
            cell.titleLabel.text = self.TALL_CELL_TITLES[indexPath.row-5]
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            // Other labels
            let labels = [
                [cell.tickerLabel1, cell.returnInPercentageLabel1, cell.returnInDollarsLabel1],
                [cell.tickerLabel2, cell.returnInPercentageLabel2, cell.returnInDollarsLabel2],
                [cell.tickerLabel3, cell.returnInPercentageLabel3, cell.returnInDollarsLabel3]
            ]
            for labelGroup in labels {
                for (index, label) in labelGroup.enumerated() {
                    if index == 0 {
                        label?.font = CustomFont.setLarge2Font()
                    }
                    else {
                        label?.font = CustomFont.setBodyFont()
                    }
                }
            }
            
            let holdings = Algorithm.getWinnerAndLoserHoldings(self.holdings)[indexPath.row-5]
            for i in 0...2 {
                if holdings.count > i {
                    let holding = holdings[i]
                    let totalGainInPercentage = holding.getReturnInPercentage()
                    let totalGainInDollars = holding.getReturnInDollars()
                    let colour = Algorithm.getReturnColour(totalGainInDollars)
                    
                    // Ticker label
                    labels[i][0]?.text = holding.ticker
                    
                    // Return in percentage label
                    labels[i][1]?.text = Algorithm.getReturnInPercentageDescription(totalGainInPercentage)
                    labels[i][1]?.textColor = colour
                    
                    // Return in dollars label
                    labels[i][2]?.text = Algorithm.getReturnInDollarsDescription(totalGainInDollars)
                    labels[i][2]?.textColor = colour
                }
                else {
                    labels[i][0]?.text = Constant.DEFAULT_LABEL
                    labels[i][1]?.text = Constant.DEFAULT_LABEL
                    labels[i][2]?.text = Constant.DEFAULT_LABEL
                    
                    labels[i][1]?.textColor = UIColor(named: "BodyText1")
                    labels[i][2]?.textColor = UIColor(named: "BodyText1")
                }
            }
            
            return cell
            
        default:
            break
        }
        
        fatalError("Wrong number of cells indicated for PerformanceCollectionViewController")
    }

}

// SOURCE: https://stackoverflow.com/questions/38028013/how-to-set-uicollectionviewcell-width-and-height-programmatically
// AUTHOR: pierre23 - https://stackoverflow.com/users/1735977/pierre23
extension PerformanceCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    /// Sets up sizing for cells in the collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.WIDE_CELL_RANGE.contains(indexPath.row) {
            let width = UIScreen.main.bounds.width - Constant.CGF_LEADING*2
            return CGSize(width: width, height: 100)
        }
        else if self.SINGLE_CELL_RANGE.contains(indexPath.row) {
            let width = (UIScreen.main.bounds.width - Constant.CGF_LEADING*3)/2
            return CGSize(width: width, height: 100)
        }
        else {
            // self.TALL_CELL_RANGE.contains(indexPath.row)
            let width = (UIScreen.main.bounds.width - Constant.CGF_LEADING*3)/2
            return CGSize(width: width, height: 320)
        }
    }
    
}
