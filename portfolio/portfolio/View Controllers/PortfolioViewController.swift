//
//  PortfolioViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

// Scrolling
// SOURCE: https://stevenpcurtis.medium.com/create-a-uistackview-in-a-uiscrollview-e2a959fa061
// Author: Steven Curtis - https://stevenpcurtis.medium.com/

import UIKit
import SwiftUI

class PortfolioViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    // Constants
    let CELL_HOLDING = "holdingCell"
    let KEYPATH_TABLEVIEW_HEIGHT = "contentSize"
    let API_KEY = "fb1e4d1cdf934bdd8ef247ea380bd80a"
    let CELL_HEIGHT: CGFloat = 65.0
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // ChartView
    let swiftUIView = ChartView()
    var chartData = ChartData(title: "Title", legend: "Legend", data: [])
    
    // Indicator
    var indicator = UIActivityIndicatorView()
    
    // Other properties
    var portfolio: CoreWatchlist?
    var shownHoldings: [Holding] = []
    
    // MARK: - Outlets
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var holdingsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var graphDurationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    // Stack views
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var graphDurationStackView: UIStackView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var totalGainStackView: UIStackView!
    @IBOutlet weak var totalEquitiesStackView: UIStackView!
    @IBOutlet weak var holdingsTitleStackView: UIStackView!
    // Labels
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var totalGainLabel: UILabel!
    @IBOutlet weak var totalGainValueLabel: UILabel!
    @IBOutlet weak var totalEquitiesLabel: UILabel!
    @IBOutlet weak var totalEquitiesValueLabel: UILabel!
    @IBOutlet weak var holdingsTitleLabel: UILabel!
    @IBOutlet weak var holdingsTitleDetailLabel: UILabel!
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        // Add the chart to the view
        addSubSwiftUIView(swiftUIView, to: view, chartData: self.chartData)
        
        // Add margins to the stack views
        self.rootStackView.directionalLayoutMargins = .init(top: 10, leading: 0, bottom: 0, trailing: 0)
        self.graphDurationStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.subtitleStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 0, trailing: 15)
        self.totalGainStackView.directionalLayoutMargins = .init(top: 10, leading: 15, bottom: 0, trailing: 15)
        self.totalEquitiesStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.holdingsTitleStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 5, trailing: 15)
        self.rootStackView.isLayoutMarginsRelativeArrangement = true
        self.graphDurationStackView.isLayoutMarginsRelativeArrangement = true
        self.subtitleStackView.isLayoutMarginsRelativeArrangement = true
        self.totalGainStackView.isLayoutMarginsRelativeArrangement = true
        self.totalEquitiesStackView.isLayoutMarginsRelativeArrangement = true
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
        
        // Make it so page scrolls even if all the contents fits on one page
        //self.scrollView.alwaysBounceVertical = true
        
        // Fonts
        self.subtitleLabel.font = CustomFont.setSubtitleFont()
        self.totalGainLabel.font = CustomFont.setBodyFont()
        self.totalGainValueLabel.font = CustomFont.setBodyFont()
        self.totalEquitiesLabel.font = CustomFont.setBodyFont()
        self.totalEquitiesValueLabel.font = CustomFont.setBodyFont()
        self.holdingsTitleLabel.font = CustomFont.setSubtitleFont()
        self.holdingsTitleDetailLabel.font = CustomFont.setSubtitleComplementaryFont()
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        // If the user has designated a different or new watchlist to be their portfolio, refresh the page's content
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.portfolio || self.portfolio?.holdings?.count != self.shownHoldings.count {
            self.portfolio = portfolio
            self.shownHoldings.removeAll()
            self.chartData.data = []
            self.chartData.title = self.portfolio?.name ?? "Watchlist Name Not Found"
            self.generateChartData(unitsBackwards: 1, unit: .day, interval: "5min", onlyUpdateGraph: false)
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
        if Calendar.current.dateComponents([.weekday], from: earlierDate!).weekday == 7 {
            // If the data being requested is for a Saturday, change it to a Friday, because the stockmarket would be closed
            earlierDate = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: earlierDate!
            )
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
                
                // Remove previous holdings data
                self.shownHoldings = []
                
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
                        // Update chart and tableview
                        self.chartData.data = combinedPrices
                        self.chartData.updateColour()
                        
                        if !onlyUpdateGraph {
                            self.holdingsTableView.reloadData()
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

}

// MARK: - TableView Methods Extension

extension PortfolioViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: holdings in portfolio
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownHoldings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: holdings in portfolio
        
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath) as! PortfolioHoldingTableViewCell
        let holding = self.shownHoldings[indexPath.row]
        
        holdingCell.tickerLabel?.text = "test"
        holdingCell.sharesLabel?.text = "test"
        holdingCell.returnInDollarsAndPercentage?.text = "test"
        holdingCell.equityLabel?.text = "test"
        
        return holdingCell
    }
    
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

extension PortfolioViewController {

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
