//
//  PerformanceCollectionViewController.swift
//  portfolio
//
//  Created by Andre Pham on 23/5/21.
//

import UIKit

private let reuseIdentifier = "Cell"

// https://stackoverflow.com/questions/31735228/how-to-make-a-simple-collection-view-with-swift
class PerformanceCollectionViewController: UICollectionViewController {
    
    let CELL_WIDE = "wideCell"
    let CELL_SINGLE = "singleCell"
    let CELL_TALL = "tallCell"
    let WIDE_CELL_INDICES = [0]
    let SINGLE_CELL_INDICES = [1, 2, 3, 4]
    let SINGLE_CELL_TITLES = ["Best Growth", "Most Profit", "Worst Growth", "Least Profit"]
    let TALL_CELL_INDICES = [5, 6]
    let TALL_CELL_TITLES = ["Winners", "Losers"]
    
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    var portfolio: CoreWatchlist?
    var shownHoldings: [Holding] = []
    // Indicator
    var indicator = UIActivityIndicatorView()
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.databaseController = appDelegate?.databaseController
        
        // SOURCE: https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
        // AUTHOR: Ahmad F - https://stackoverflow.com/users/5501940/ahmad-f
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlChanged(_:)), for: .valueChanged)
        self.collectionView.refreshControl = self.refreshControl
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView!.contentInset = UIEdgeInsets(top: 5, left: 15, bottom: 20, right: 15)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 15 // spacing left/right
        layout.minimumLineSpacing = 15 // spacing up/down
        self.collectionView.frame = self.view.frame
        self.collectionView.collectionViewLayout = layout

        
        // Add a loading indicator
        self.indicator.style = UIActivityIndicatorView.Style.large
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.indicator)
        
        // Centres the loading indicator
        NSLayoutConstraint.activate([
            self.indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            self.indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        // If the user has designated a different or new watchlist to be their portfolio, refresh the page's content
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.portfolio || self.portfolio?.holdings?.count != self.shownHoldings.count {
            self.portfolio = portfolio
            self.refresh()
        }
    }
    
    @objc func refreshControlChanged(_ sender: AnyObject) {
        if !self.collectionView.isDragging {
            self.refresh()
        }
    }
    
    // SOURCE: https://stackoverflow.com/questions/22225207/uirefreshcontrol-jitters-when-pulled-down-and-held
    // AUTHOR: Devin - https://stackoverflow.com/users/968108/devin
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.refreshControl.isRefreshing {
            self.refresh()
        }
    }
    
    func refresh() {
        self.shownHoldings.removeAll()
        self.refreshControl.endRefreshing() // End before loading indicator begins
        self.generateData(unitsBackwards: 1, unit: .day, interval: "30min", onlyUpdateGraph: false)
    }
    
    /// Assigns calls a request to the API which in turn loads data into the chart
    func generateData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        
        self.portfolio = self.databaseController?.retrievePortfolio()
        guard let portfolio = self.portfolio else {
            return
        }
        
        let tickers = Algorithm.getTickerQuery(portfolio)
        let previousOpenDate = Algorithm.getPreviousOpenDateQuery(unit: unit, unitsBackwards: unitsBackwards)
        
        indicator.startAnimating()
        
        // Calls the API which in turn provides data to the chart
        self.requestTickerWebData(tickers: tickers, startDate: previousOpenDate, interval: interval, onlyUpdateGraph: onlyUpdateGraph)
    }
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data
    func requestTickerWebData(tickers: String, startDate: String, interval: String, onlyUpdateGraph: Bool) {
        let requestURLComponents = Algorithm.getRequestURLComponents(tickers: tickers, interval: interval, startDate: startDate)
        
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
                
                if tickers.contains(",") {
                    // Multiple ticker request
                    let tickerResponse = try decoder.decode(DecodedTickerArray.self, from: data!)
                    
                    // For every ticker with data returned, create a new Holding with its data
                    for ticker in tickerResponse.tickerArray {
                        if let holding = Algorithm.createHoldingFromTickerResponse(ticker) {
                            self.shownHoldings.append(holding)
                        }
                    }
                }
                else {
                    // Single ticker request
                    let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                    
                    if let holding = Algorithm.createHoldingFromTickerResponse(tickerResponse) {
                        self.shownHoldings.append(holding)
                    }
                }
                // Add the purchase data for each holding created
                let coreHoldings = self.portfolio?.holdings?.allObjects as! [CoreHolding]
                Algorithm.transferPurchasesFromCoreToHoldings(coreHoldings: coreHoldings, holdings: self.shownHoldings)
                
                // If no holdings were created from the API request, don't run the following code because it'll crash
                if self.shownHoldings.count > 0 {
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_WIDE, for: indexPath as IndexPath) as! WidePerformanceCollectionViewCell
            
            let totalReturnInPercentage = Algorithm.getAverageAnnualReturnInPercentage(shownHoldings)
            
            cell.titleLabel.text = "Average\nAnnual\nReturn"
            if totalReturnInPercentage.isNaN {
                cell.percentGainLabel.text = Constant.DEFAULT_LABEL
                cell.percentGainLabel.textColor = UIColor.black
            }
            else {
                cell.percentGainLabel.text = Algorithm.getReturnInPercentageDescription(totalReturnInPercentage)
                cell.percentGainLabel.textColor = Algorithm.getReturnColour(totalReturnInPercentage)
            }
            
            
            cell.titleLabel.font = CustomFont.setSubtitle2Font()
            cell.percentGainLabel.font = CustomFont.setLargeFont()
            var sizeReduction = 0.0
            if abs(totalReturnInPercentage) >= 100 {
                sizeReduction += totalReturnInPercentage*0.0009 + 2.5556
            }
            cell.percentGainLabel.font = CustomFont.setFont(size: CustomFont.LARGE_SIZE - sizeReduction, style: CustomFont.LARGE_STYLE, weight: CustomFont.LARGE_WEIGHT)
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
            
        case 1...4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_SINGLE, for: indexPath as IndexPath) as! SinglePerformanceCollectionViewCell
            
            let titles = ["Most Growth", "Most Return", "Least Growth", "Least Return"]
            cell.titleLabel.text = titles[indexPath.row-1]
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            cell.tickerLabel.font = CustomFont.setLarge2Font()
            cell.percentGainLabel.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            var rank = "Worst"
            if indexPath.row <= 2 {
                rank = "Best"
            }
            let returnFormat = ["Dollars", "Percentage"][indexPath.row%2]
            if let holding = Algorithm.getBestOrWorstHolding(self.shownHoldings, Best_or_Worst: rank, Percentage_or_Dollars: returnFormat) {
                let ticker = holding.ticker
                var returnValue: Double
                if returnFormat == "Dollars" {
                    returnValue = holding.getReturnInDollars()
                }
                else {
                    returnValue = holding.getReturnInPercentage()
                }
                let colour = Algorithm.getReturnColour(returnValue)
                
                cell.tickerLabel.text = ticker
                if returnFormat == "Dollars" {
                    cell.percentGainLabel.text = Algorithm.getReturnInDollarsDescription(returnValue)
                }
                else {
                    cell.percentGainLabel.text = Algorithm.getReturnInPercentageDescription(returnValue)
                }
                cell.percentGainLabel.textColor = colour
            }
            else {
                cell.tickerLabel.text = Constant.DEFAULT_LABEL
                cell.percentGainLabel.text = Constant.DEFAULT_LABEL
            }
            
            return cell
            
        case 5...6:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TALL, for: indexPath as IndexPath) as! TallPerformanceCollectionViewCell
            
            let titles = ["Winners", "Losers"]
            cell.titleLabel.text = titles[indexPath.row-5]
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            let holdings = Algorithm.getWinnerAndLoserHoldings(self.shownHoldings)[indexPath.row-5]
            let labels = [
                [cell.tickerLabel1, cell.gainInPercentageLabel1, cell.gainInDollarsLabel1],
                [cell.tickerLabel2, cell.gainInPercentageLabel2, cell.gainInDollarsLabel2],
                [cell.tickerLabel3, cell.gainInPercentageLabel3, cell.gainInDollarsLabel3]
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
            
            for i in 0...2 {
                if holdings.count > i {
                    let holding = holdings[i]
                    let totalGainInPercentage = holding.getReturnInPercentage()
                    let totalGainInDollars = holding.getReturnInDollars()
                    let colour = Algorithm.getReturnColour(totalGainInDollars)
                    
                    labels[i][0]?.text = holding.ticker
                    labels[i][1]?.text = Algorithm.getReturnInPercentageDescription(totalGainInPercentage)
                    labels[i][2]?.text = Algorithm.getReturnInDollarsDescription(totalGainInDollars)
                    
                    labels[i][1]?.textColor = colour
                    labels[i][2]?.textColor = colour
                }
                else {
                    labels[i][0]?.text = Constant.DEFAULT_LABEL
                    labels[i][1]?.text = Constant.DEFAULT_LABEL
                    labels[i][2]?.text = Constant.DEFAULT_LABEL
                    
                    labels[i][1]?.textColor = UIColor.black
                    labels[i][2]?.textColor = UIColor.black
                }
            }
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
            
        default:
            break
        }
        
        fatalError("Wrong number of cells indicated for PerformanceCollectionViewController")
    }

}

// https://stackoverflow.com/questions/38028013/how-to-set-uicollectionviewcell-width-and-height-programmatically
extension PerformanceCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let width = UIScreen.main.bounds.width - CGFloat(Constant.LEADING)*2
            return CGSize(width: width, height: 100)
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let width = (UIScreen.main.bounds.width - CGFloat(Constant.LEADING)*3)/2
            return CGSize(width: width, height: 100)
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            let width = (UIScreen.main.bounds.width - CGFloat(Constant.LEADING)*3)/2
            return CGSize(width: width, height: 320)
        }
    }
    
}
