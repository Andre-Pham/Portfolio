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
    
    let API_KEY = "fb1e4d1cdf934bdd8ef247ea380bd80a"
    
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
        self.generateChartData(unitsBackwards: 1, unit: .day, interval: "30min", onlyUpdateGraph: false)
    }
    
    /// Assigns calls a request to the API which in turn loads data into the chart
    func generateChartData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        // Generates argument for what tickers data will be retrieved for
        var tickers = ""
        self.portfolio = self.databaseController?.retrievePortfolio()
        let holdings = self.portfolio?.holdings?.allObjects as! [CoreHolding]
        for holding in holdings {
            tickers += holding.ticker ?? ""
            tickers += ","
        }
        // Remove unnecessary extra ","
        tickers = String(tickers.dropLast())
        
        // Generates the previous day's date, so we can retrieve intraday prices
        var earlierDate = Calendar.current.date(
            byAdding: unit,
            value: -unitsBackwards,
            to: Date()
        )
        var weekdayNumber = Int(Calendar.current.dateComponents([.weekday], from: earlierDate!).weekday ?? 2)
        while [1, 7].contains(weekdayNumber) {
            // 1: Sunday, 7: Saturday
            // If the data being requested is for Saturday/Sunday, change it to a Friday, because the stockmarket would be closed
            earlierDate = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: earlierDate!
            )
            // One day backwards; 1 (Sun) -> 7 (Sat), 7 (Sat) -> 6 (Fri)
            weekdayNumber -= 1
            if weekdayNumber == 0 {
                weekdayNumber = 7
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let earlierDateFormatted = formatter.string(from: earlierDate!)
        
        // Calls the API which in turn provides data to the chart
        indicator.startAnimating()
        self.requestTickerWebData(tickers: tickers, startDate: earlierDateFormatted, interval: interval, onlyUpdateGraph: onlyUpdateGraph)
    }
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data
    func requestTickerWebData(tickers: String, startDate: String, interval: String, onlyUpdateGraph: Bool) {
        // https://api.twelvedata.com/time_series?symbol=MSFT,AMZN&interval=5min&start_date=2021-4-26&timezone=Australia/Sydney&apikey=fb1e4d1cdf934bdd8ef247ea380bd80a
        
        // Form URL from different components
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/time_series"
        requestURLComponents.queryItems = [
            URLQueryItem(name: "symbol", value: tickers),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "start_date", value: startDate), // yyyy-mm-dd
            URLQueryItem(name: "apikey", value: self.API_KEY),
        ]
        
        // Ensure URL is valid
        guard let requestURL = requestURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        print(requestURL)
        
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
                        // Get price data in Double type retrieved from API
                        var prices: [Double] = []
                        for stringPrice in ticker.values {
                            if let price = Double(stringPrice.open) {
                                prices.append(price)
                            }
                        }
                        // Create Holding
                        self.shownHoldings.append(
                            Holding(ticker: ticker.meta.symbol, prices: prices, currentPrice: prices.last ?? 0)
                        )
                    }
                }
                else {
                    // Single ticker request
                    let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                    
                    // Get price data in Double type retreived from API
                    var prices: [Double] = []
                    var currentPrice: Double? = nil
                    for stringPrice in tickerResponse.values {
                        if let price = Double(stringPrice.open) {
                            prices.append(price)
                        }
                        if currentPrice == nil {
                            currentPrice = Double(stringPrice.close)
                        }
                    }
                    // Create Holding
                    self.shownHoldings.append(
                        Holding(ticker: tickerResponse.meta.symbol, prices: prices, currentPrice: currentPrice ?? 0)
                    )
                }
                // Add the purchase data for each holding created
                let coreHoldings = self.portfolio?.holdings?.allObjects as! [CoreHolding]
                for coreHolding in coreHoldings {
                    for holding in self.shownHoldings {
                        if coreHolding.ticker == holding.ticker {
                            holding.purchases = coreHolding.purchases?.allObjects as! [CorePurchase]
                        }
                    }
                }
                
                // If no holdings were created from the API request, don't run the following code because it'll crash
                if self.shownHoldings.count > 0 {
                    // Find how many prices to plot
                    var num_prices = 0
                    for holding in self.shownHoldings {
                        if holding.prices.count > num_prices {
                            num_prices = holding.prices.count
                        }
                    }
                    // Merge all the prices of the holdings to create the single graph
                    var combinedPrices = [Double](repeating: 0.0, count: num_prices)
                    for holding in self.shownHoldings {
                        let holdingPercentages = holding.convertPricesToPercentages()
                        for priceIndex in 0..<holdingPercentages.count {
                            // API provides values in reverse order
                            let reverseIndex = abs(priceIndex - (holdingPercentages.count-1))
                            
                            combinedPrices[reverseIndex] += holdingPercentages[priceIndex]
                        }
                    }
                    
                    DispatchQueue.main.async {
                        // Do nothing for now
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
            
            let shownReturnInPercentage = Calculations.roundToTwo(Calculations.getAverageAnnualReturnInPercentage(shownHoldings))
            let prefix = Calculations.getPrefix(shownReturnInPercentage)
            
            cell.titleLabel.text = "Average\nAnnual\nReturn"
            cell.percentGainLabel.text = "\(prefix) \(abs(shownReturnInPercentage))%"
            
            cell.titleLabel.font = CustomFont.setSubtitle2Font()
            cell.percentGainLabel.font = CustomFont.setLargeFont()
            var sizeReduction = 0.0
            if abs(shownReturnInPercentage) >= 100 {
                sizeReduction += shownReturnInPercentage*0.0009 + 2.5556
            }
            cell.percentGainLabel.font = CustomFont.setFont(size: CustomFont.LARGE_SIZE - sizeReduction, style: CustomFont.LARGE_STYLE, weight: CustomFont.LARGE_WEIGHT)
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            cell.percentGainLabel.textColor = Calculations.getReturnColour(shownReturnInPercentage)
        
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
            if let holding = Calculations.getBestOrWorstHolding(self.shownHoldings, Best_or_Worst: rank, Percentage_or_Dollars: returnFormat) {
                let ticker = holding.ticker
                var returnValue: Double
                if returnFormat == "Dollars" {
                    returnValue = Calculations.roundToTwo(holding.getReturnInDollars())
                }
                else {
                    returnValue = Calculations.roundToTwo(holding.getReturnInPercentage())
                }
                let prefix = Calculations.getPrefix(returnValue)
                let colour = Calculations.getReturnColour(returnValue)
                
                cell.tickerLabel.text = ticker
                if returnFormat == "Dollars" {
                    cell.percentGainLabel.text = "\(prefix) $\(abs(returnValue))"
                }
                else {
                    cell.percentGainLabel.text = "\(prefix) \(abs(returnValue))%"
                }
                cell.percentGainLabel.textColor = colour
            }
            else {
                cell.tickerLabel.text = "-"
                cell.percentGainLabel.text = "-"
            }
            
            return cell
            
        case 5...6:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TALL, for: indexPath as IndexPath) as! TallPerformanceCollectionViewCell
            
            let titles = ["Winners", "Losers"]
            cell.titleLabel.text = titles[indexPath.row-5]
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            cell.tickerLabel1.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel1.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel1.font = CustomFont.setBodyFont()
            
            cell.tickerLabel2.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel2.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel2.font = CustomFont.setBodyFont()
            
            cell.tickerLabel3.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel3.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel3.font = CustomFont.setBodyFont()
            
            let holdings = Calculations.getWinnerAndLoserHoldings(self.shownHoldings)[indexPath.row-5]
            let labels = [
                [cell.tickerLabel1, cell.gainInPercentageLabel1, cell.gainInDollarsLabel1],
                [cell.tickerLabel2, cell.gainInPercentageLabel2, cell.gainInDollarsLabel2],
                [cell.tickerLabel3, cell.gainInPercentageLabel3, cell.gainInDollarsLabel3]
            ]
            
            for i in 0...2 {
                if holdings.count > i {
                    let holding = holdings[i]
                    let shownGainInPercentage = Calculations.roundToTwo(holding.getReturnInPercentage())
                    let shownGainInDollars = Calculations.roundToTwo(holding.getReturnInDollars())
                    let prefix = Calculations.getPrefix(shownGainInDollars)
                    let colour = Calculations.getReturnColour(shownGainInDollars)
                    
                    labels[i][0]?.text = holding.ticker
                    labels[i][1]?.text = "\(prefix) \(abs(shownGainInPercentage))%"
                    labels[i][2]?.text = "\(prefix) $\(abs(shownGainInDollars))"
                    
                    labels[i][1]?.textColor = colour
                    labels[i][2]?.textColor = colour
                }
                else {
                    labels[i][0]?.text = "-"
                    labels[i][1]?.text = "-"
                    labels[i][2]?.text = "-"
                    
                    labels[i][1]?.textColor = UIColor.black
                    labels[i][2]?.textColor = UIColor.black
                }
            }
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
            
        default:
            break
        }
        /*
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_WIDE, for: indexPath as IndexPath) as! WidePerformanceCollectionViewCell
            
            let shownReturnInPercentage = Calculations.roundToTwo(Calculations.getAverageAnnualReturnInPercentage(shownHoldings))
            let prefix = Calculations.getPrefix(shownReturnInPercentage)
            
            cell.titleLabel.text = "Average\nAnnual\nReturn"
            cell.percentGainLabel.text = "\(prefix) \(abs(shownReturnInPercentage))%"
            
            cell.titleLabel.font = CustomFont.setSubtitle2Font()
            cell.percentGainLabel.font = CustomFont.setLargeFont()
            var sizeReduction = 0.0
            if abs(shownReturnInPercentage) >= 100 {
                sizeReduction += shownReturnInPercentage*0.0009 + 2.5556
            }
            cell.percentGainLabel.font = CustomFont.setFont(size: CustomFont.LARGE_SIZE - sizeReduction, style: CustomFont.LARGE_STYLE, weight: CustomFont.LARGE_WEIGHT)
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            cell.percentGainLabel.textColor = Calculations.getReturnColour(shownReturnInPercentage)
        
            return cell
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_SINGLE, for: indexPath as IndexPath) as! SinglePerformanceCollectionViewCell
            
            let holding = Calculations.getBestGrowth(self.shownHoldings)
            let ticker =
            
            cell.titleLabel.text = self.SINGLE_CELL_TITLES[indexPath.row]
            cell.tickerLabel.text = "MMMM"
            cell.percentGainLabel.text = "-10.24%"
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            cell.tickerLabel.font = CustomFont.setLarge2Font()
            cell.percentGainLabel.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TALL, for: indexPath as IndexPath) as! TallPerformanceCollectionViewCell
            
            cell.titleLabel.text = "Winners"
            
            cell.tickerLabel1.text = "MMMM"
            cell.gainInPercentageLabel1.text = "-10.24%"
            cell.gainInDollarsLabel1.text = "-$10.24"
            
            cell.tickerLabel2.text = "MMMM"
            cell.gainInPercentageLabel2.text = "-10.24%"
            cell.gainInDollarsLabel2.text = "-$10.24"
            
            cell.tickerLabel3.text = "MMMM"
            cell.gainInPercentageLabel3.text = "-10.24%"
            cell.gainInDollarsLabel3.text = "-$10.24"
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            cell.tickerLabel1.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel1.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel1.font = CustomFont.setBodyFont()
            
            cell.tickerLabel2.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel2.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel2.font = CustomFont.setBodyFont()
            
            cell.tickerLabel3.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel3.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel3.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
        }
        */
        fatalError("Wrong number of cells indicated for PerformanceCollectionViewController")
    }

}

// https://stackoverflow.com/questions/38028013/how-to-set-uicollectionviewcell-width-and-height-programmatically
extension PerformanceCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let width = UIScreen.main.bounds.width - 15*2
            return CGSize(width: width, height: 100)
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let width = (UIScreen.main.bounds.width - 15*3)/2
            return CGSize(width: width, height: 100)
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            let width = (UIScreen.main.bounds.width - 15*3)/2
            return CGSize(width: width, height: 320)
        }
    }
    
}
