//
//  DashboardViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

// Scrolling
// SOURCE: https://stevenpcurtis.medium.com/create-a-uistackview-in-a-uiscrollview-e2a959fa061
// Author: Steven Curtis - https://stevenpcurtis.medium.com/

import UIKit
import SwiftUI

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    // Constants
    let CELL_HOLDING = "holdingCell"
    let KEYPATH_TABLEVIEW_HEIGHT = "contentSize"
    let CELL_HEIGHT: CGFloat = 30.0
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // ChartView
    let swiftUIView = ChartView()
    var chartData = ChartData(title: "Title", legend: "Legend", data: [])
    
    // Loading indicators
    var indicator = UIActivityIndicatorView()
    var refreshControl = UIRefreshControl()
    
    // Other properties
    var shownWatchlist: CoreWatchlist?
    var shownHoldings: [Holding] = []
    
    // MARK: - Outlets
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var holdingsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var graphDurationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    // Stack views
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var graphDurationStackView: UIStackView!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var dayAndTotalGainStackView: UIStackView!
    @IBOutlet weak var holdingsTitleStackView: UIStackView!
    // Labels
    @IBOutlet weak var todaysDateLabel: UILabel!
    @IBOutlet weak var daysGainLabel: UILabel!
    @IBOutlet weak var totalGainLabel: UILabel!
    @IBOutlet weak var holdingsTitleLabel: UILabel!
    @IBOutlet weak var holdingsTitleDetailLabel: UILabel!
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SOURCE: https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
        // AUTHOR: Ahmad F - https://stackoverflow.com/users/5501940/ahmad-f
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlChanged(_:)), for: .valueChanged)
        self.scrollView.refreshControl = self.refreshControl
        
        // Add the chart to the view
        addSubSwiftUIView(swiftUIView, to: view, chartData: self.chartData)
        
        // Add margins to the stack views
        self.rootStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 0)
        self.graphDurationStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.dateStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 0, trailing: 15)
        self.dayAndTotalGainStackView.directionalLayoutMargins = .init(top: 10, leading: 15, bottom: 0, trailing: 15)
        self.holdingsTitleStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 5, trailing: 15)
        self.rootStackView.isLayoutMarginsRelativeArrangement = true
        self.graphDurationStackView.isLayoutMarginsRelativeArrangement = true
        self.dateStackView.isLayoutMarginsRelativeArrangement = true
        self.dayAndTotalGainStackView.isLayoutMarginsRelativeArrangement = true
        self.holdingsTitleStackView.isLayoutMarginsRelativeArrangement = true
        
        // Add a loading indicator
        self.indicator.style = UIActivityIndicatorView.Style.large
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.indicator)
        
        // Centres the loading indicator
        NSLayoutConstraint.activate([
            self.indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            self.indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        // Fonts
        self.todaysDateLabel.font = CustomFont.setSubtitleFont()
        self.daysGainLabel.font = CustomFont.setBodyFont()
        self.totalGainLabel.font = CustomFont.setBodyFont()
        self.holdingsTitleLabel.font = CustomFont.setSubtitleFont()
        self.holdingsTitleDetailLabel.font = CustomFont.setSubtitleComplementaryFont()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        // Make it so page scrolls even if all the contents fits on one page
        self.scrollView.alwaysBounceVertical = true
        // Delegate used for checking when user stops scrolling, so page can refresh
        self.scrollView.delegate = self
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        var currentDateFormatted = formatter.string(from: currentDate)
        formatter.dateFormat = "yyyy"
        let currentYearFormatted = formatter.string(from: currentDate)
        currentDateFormatted = currentDateFormatted.replacingOccurrences(of: ", \(currentYearFormatted)", with: "")
        self.todaysDateLabel.text = currentDateFormatted
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        // If the user has designated a different or new watchlist to be their portfolio, refresh the page's content
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.shownWatchlist || self.shownWatchlist?.holdings?.count != self.shownHoldings.count {
            self.shownWatchlist = portfolio
            self.refresh()
        }
        
        // Adds observer which calls observeValue when number of tableview cells changes
        self.holdingsTableView.addObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT, options: .new, context: nil)
        self.holdingsTableView.reloadData()
    }
    
    /// Calls before the view disappears on screen
    override func viewWillDisappear(_ animated: Bool) {
        // Removes observer which calls observeValue when number of tableview cells changes
        self.holdingsTableView.removeObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT)
    }
    
    @objc func refreshControlChanged(_ sender: AnyObject) {
        if !self.scrollView.isDragging {
            self.refresh()
        }
    }
    
    // SOURCE: https://stackoverflow.com/questions/22225207/uirefreshcontrol-jitters-when-pulled-down-and-held
    // AUTHOR: Devin - https://stackoverflow.com/users/968108/devin
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.refreshControl.isRefreshing {
            self.refresh()
        }
    }
    
    func refresh() {
        self.shownHoldings.removeAll()
        self.chartData.data = []
        self.chartData.title = self.shownWatchlist?.name ?? "-"
        self.refreshControl.endRefreshing() // End before loading indicator begins
        self.generateChartData(unitsBackwards: 1, unit: .day, interval: "5min", onlyUpdateGraph: false)
    }
    
    /// Calls when triggered by an observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // SOURCE: https://www.youtube.com/watch?v=INkeINPZddo
        // AUTHOR: Divyesh Gondaliya - https://www.youtube.com/channel/UC4pRJw6rNrHuFZV3aOELJkA
        if keyPath == KEYPATH_TABLEVIEW_HEIGHT {
            // Changes TableView height based on number of cells so they're not squished into a nested scroll view
            if let newValue = change?[.newKey] {
                let newSize = newValue as! CGSize
                self.holdingsTableViewHeight.constant = newSize.height
            }
        }
    }
    
    @IBAction func graphDurationSegmentedControlChanged(_ sender: Any) {
        let graphDuration = self.graphDurationSegmentedControl.titleForSegment(at: self.graphDurationSegmentedControl.selectedSegmentIndex)
        self.chartData.data = []
        switch graphDuration {
        case "24H":
            self.generateChartData(unitsBackwards: 1, unit: .day, interval: "5min", onlyUpdateGraph: true)
            break
        case "1W":
            self.generateChartData(unitsBackwards: 7, unit: .day, interval: "30min", onlyUpdateGraph: true)
            break
        case "1M":
            self.generateChartData(unitsBackwards: 1, unit: .month, interval: "1day", onlyUpdateGraph: true)
            break
        case "1Y":
            self.generateChartData(unitsBackwards: 1, unit: .year, interval: "1week", onlyUpdateGraph: true)
            break
        case "5Y":
            self.generateChartData(unitsBackwards: 5, unit: .year, interval: "1month", onlyUpdateGraph: true)
            break
        case "10Y":
            self.generateChartData(unitsBackwards: 10, unit: .year, interval: "1month", onlyUpdateGraph: true)
            break
        default:
            break
        }
    }
    
    /// Assigns calls a request to the API which in turn loads data into the chart
    func generateChartData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        // Generates argument for what tickers data will be retrieved for
        var tickers = ""
        // TODO: Use guard statement to end early if there are no holdings
        let holdings = self.shownWatchlist?.holdings?.allObjects as! [CoreHolding]
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
            URLQueryItem(name: "apikey", value: Constant.API_KEY),
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
                
                // Remove previous holdings data
                self.shownHoldings = []
                
                if tickers.contains(",") {
                    // Multiple ticker request
                    let tickerResponse = try decoder.decode(DecodedTickerArray.self, from: data!)
                    
                    // For every ticker with data returned, create a new Holding with its data
                    for ticker in tickerResponse.tickerArray {
                        // Get price data in Double type retrieved from API
                        var prices: [Double] = []
                        var currentPrice: Double? = nil
                        for stringPrice in ticker.values {
                            if let price = Double(stringPrice.open) {
                                prices.append(price)
                            }
                            if currentPrice == nil {
                                currentPrice = Double(stringPrice.close)
                            }
                        }
                        // Create Holding
                        self.shownHoldings.append(
                            Holding(ticker: ticker.meta.symbol, prices: prices, currentPrice: currentPrice ?? 0)
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
                let coreHoldings = self.shownWatchlist?.holdings?.allObjects as! [CoreHolding]
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
                        // Update chart and tableview
                        self.chartData.data = combinedPrices
                        self.chartData.updateColour()
                        
                        if !onlyUpdateGraph {
                            self.holdingsTableView.reloadData()
                        }
                        
                        if let watchlistIsOwned = self.shownWatchlist?.owned {
                            if watchlistIsOwned && !onlyUpdateGraph {
                                var dayGainDollars = 0.0
                                var dayGainPercentage = 0.0
                                
                                for holding in self.shownHoldings {
                                    if let currentPrice = holding.currentPrice, let previousPrice = holding.prices.last {
                                        
                                        dayGainDollars += holding.getSharesOwned()*(currentPrice - previousPrice)
                                        //dayGainPercentage += 100*(currentPrice/previousPrice - 1)
                                        //dayGainPercentage += 100*(holding.getEquity()/(holding.getEquity() - dayGainDollars) - 1)
                                    }
                                }
                                let totalEquity = Algorithm.getTotalEquities(self.shownHoldings)
                                dayGainPercentage = 100*((totalEquity/(totalEquity - dayGainDollars) - 1))
                                
                                // Round to 2 decimal places
                                dayGainDollars = Algorithm.roundToTwo(dayGainDollars)
                                dayGainPercentage = Algorithm.roundToTwo(dayGainPercentage)
                                
                                self.daysGainLabel.text = "\(Algorithm.getPrefix(dayGainDollars)) $\(abs(dayGainDollars)) (\(dayGainPercentage)%) Day"
                                self.daysGainLabel.textColor = Algorithm.getReturnColour(dayGainDollars)
                                
                                let shownTotalReturnInDollars = Algorithm.roundToTwo(Algorithm.getTotalReturnInDollars(self.shownHoldings))
                                let shownTotalReturnInPercentage = Algorithm.roundToTwo(Algorithm.getTotalReturnInPercentage(self.shownHoldings))
                                let shownPrefix = Algorithm.getPrefix(shownTotalReturnInDollars)
                                self.totalGainLabel.text = "\(shownPrefix) $\(shownTotalReturnInDollars) (\(shownTotalReturnInPercentage)%) Total"
                                self.totalGainLabel.textColor = Algorithm.getReturnColour(shownTotalReturnInDollars)
                            }
                        }
                    }
                }
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "switchWatchlist" {
            // Define the destination ViewController to assign its properties
            let destination = segue.destination as! SwitchDashboardWatchlistViewController
            
            // Assign properties to the destination ViewController
            destination.switchWatchlistDelegate = self
        }
    }

}

extension DashboardViewController: SwitchWatchlistDelegate {
    
    func switchWatchlist(_ newWatchlist: CoreWatchlist) {
        self.shownWatchlist = newWatchlist
        self.refresh()
    }
    
}

// MARK: - TableView Methods Extension

extension DashboardViewController {
    
    /// Returns how many sections the TableView has
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: holdings in watchlist
        return 1
    }
    
    /// Returns the number of rows in any given section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownHoldings.count
    }
    
    /// Creates the cells and contents of the TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: holdings in watchlist
        
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
        let holding = self.shownHoldings[indexPath.row]
        
        let currentPrice = holding.currentPrice!
        let previousPrice = holding.prices.last!
        
        var dayGainDollars = holding.getSharesOwned()*(currentPrice - previousPrice)
        var dayGainPercentage = 100*(holding.getEquity()/(holding.getEquity() - dayGainDollars) - 1)
        
        // Round to 2 decimal places
        dayGainDollars = Algorithm.roundToTwo(dayGainDollars)
        dayGainPercentage = Algorithm.roundToTwo(dayGainPercentage)
        
        let prefix = Algorithm.getPrefix(dayGainDollars)
        
        holdingCell.textLabel?.text = holding.ticker
        //holdingCell.detailTextLabel?.text = String(holding.currentPrice!)
        holdingCell.detailTextLabel?.text = "\(prefix) $\(abs(dayGainDollars)) (\(dayGainPercentage)%)"
        
        holdingCell.textLabel?.font = CustomFont.setBodyFont()
        holdingCell.detailTextLabel?.font = CustomFont.setBodyFont()
        
        holdingCell.detailTextLabel?.textColor = Algorithm.getReturnColour(dayGainDollars)
        
        return holdingCell
    }
    
    /// Returns whether a given section can be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Holdings can't be deleted from this page
        return false
    }
    
    /// Returns the height of each cell
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.CELL_HEIGHT
    }
    
}

// MARK: - SwiftUI Chart Methods Extension

extension DashboardViewController {

    /// Adds the SwiftUI chart view as a child to DashboardViewController
    func addSubSwiftUIView<Content>(_ swiftUIView: Content, to view: UIView, chartData: ChartData) where Content : View {
        // SOURCE: https://www.avanderlee.com/swiftui/integrating-swiftui-with-uikit/
        // AUTHOR: ANTOINE VAN DER LEE - https://www.avanderlee.com/
        
        // Create SwiftUI view (chartViewHostingController) and add it as a child to DashboardViewController
        let chartViewHostingController = UIHostingController(rootView: swiftUIView.environmentObject(chartData))
        addChild(chartViewHostingController)

        // Insert the SwiftUI view without overlap
        rootStackView.insertArrangedSubview(chartViewHostingController.view, at: 0)

        // Add constraints to the SwiftUI view
        chartViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            chartViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chartViewHostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.40)
        ]
        NSLayoutConstraint.activate(constraints)

        // Notify the SwiftUI view that it has been moved to DashboardViewController
        chartViewHostingController.didMove(toParent: self)
    }
    
}
