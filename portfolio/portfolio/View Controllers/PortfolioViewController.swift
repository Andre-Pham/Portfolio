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
    let CELL_HEIGHT: CGFloat = 65.0
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // ChartView
    let swiftUIView = ChartView()
    var chartData = ChartData(title: "Title", legend: "Legend", data: [])
    
    // Loading indicators
    var indicator = UIActivityIndicatorView()
    var refreshControl = UIRefreshControl()
    
    // Other properties
    var portfolio: CoreWatchlist?
    var holdings: [Holding] = []
    
    // MARK: - Outlets
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var holdingsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var graphDurationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Stack views
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var graphDurationStackView: UIStackView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var totalReturnStackView: UIStackView!
    @IBOutlet weak var totalEquitiesStackView: UIStackView!
    @IBOutlet weak var holdingsTitleStackView: UIStackView!
    
    // Labels
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var totalReturnDescriptionLabel: UILabel!
    @IBOutlet weak var totalReturnLabel: UILabel!
    @IBOutlet weak var totalEquitiesDescriptionLabel: UILabel!
    @IBOutlet weak var totalEquitiesLabel: UILabel!
    @IBOutlet weak var holdingsSubtitleLabel: UILabel!
    @IBOutlet weak var holdingsSubtitleDetailLabel: UILabel!
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the chart to the view
        self.addSubSwiftUIView(swiftUIView, to: view, chartData: self.chartData)
        
        // Add margins to the stack views
        self.rootStackView.directionalLayoutMargins = .init(top: 10, leading: 0, bottom: 20, trailing: 0)
        self.graphDurationStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.subtitleStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 0, trailing: 15)
        self.totalReturnStackView.directionalLayoutMargins = .init(top: 10, leading: 15, bottom: 0, trailing: 15)
        self.totalEquitiesStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.holdingsTitleStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 5, trailing: 15)
        self.rootStackView.isLayoutMarginsRelativeArrangement = true
        self.graphDurationStackView.isLayoutMarginsRelativeArrangement = true
        self.subtitleStackView.isLayoutMarginsRelativeArrangement = true
        self.totalReturnStackView.isLayoutMarginsRelativeArrangement = true
        self.totalEquitiesStackView.isLayoutMarginsRelativeArrangement = true
        self.holdingsTitleStackView.isLayoutMarginsRelativeArrangement = true
        
        // SOURCE: https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
        // AUTHOR: Ahmad F - https://stackoverflow.com/users/5501940/ahmad-f
        // Add scroll up to refresh
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlChanged(_:)), for: .valueChanged)
        self.scrollView.refreshControl = self.refreshControl
        
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
        self.subtitleLabel.font = CustomFont.setSubtitleFont()
        self.totalReturnDescriptionLabel.font = CustomFont.setBodyFont().bold
        self.totalReturnLabel.font = CustomFont.setBodyFont()
        self.totalEquitiesDescriptionLabel.font = CustomFont.setBodyFont().bold
        self.totalEquitiesLabel.font = CustomFont.setBodyFont()
        self.holdingsSubtitleLabel.font = CustomFont.setSubtitleFont()
        self.holdingsSubtitleDetailLabel.font = CustomFont.setSubtitleComplementaryFont()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Link tableView to self
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        // Make it so page scrolls even if all the contents fits on one page
        self.scrollView.alwaysBounceVertical = true
        // Delegate used for checking when user stops scrolling, so page can refresh
        self.scrollView.delegate = self
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        if self.chartData.data.isEmpty {
            // Package SwiftUICharts has a bug where if the chart is interacted with but isn't loaded in yet, the application fatally crashes
            self.view.isUserInteractionEnabled = false
        }
        // If the user has designated a different or new watchlist to be their portfolio, refresh the page's content
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.portfolio || self.portfolio?.holdings?.count != self.holdings.count {
            self.portfolio = portfolio
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
    
    /// Calls when the user scrolls up to refresh
    @objc func refreshControlChanged(_ sender: AnyObject) {
        if !self.scrollView.isDragging {
            self.refresh()
        }
    }
    
    // SOURCE: https://stackoverflow.com/questions/22225207/uirefreshcontrol-jitters-when-pulled-down-and-held
    // AUTHOR: Devin - https://stackoverflow.com/users/968108/devin
    /// Calls when the user stops dragging, used to detect when to refresh after user scrolls up and holds
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.refreshControl.isRefreshing {
            self.refresh()
        }
    }
    
    /// Refreshes the page's content
    func refresh() {
        // Package SwiftUICharts has a bug where if the chart is interacted with but isn't loaded in yet, the application fatally crashes
        self.view.isUserInteractionEnabled = false
        
        self.holdings.removeAll()
        self.chartData.data = []
        self.chartData.title = self.portfolio?.name ?? Constant.DEFAULT_LABEL
        self.refreshControl.endRefreshing() // End before loading indicator begins
        self.graphDurationSegmentedControl.selectedSegmentIndex = 0
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
    
    /// Calls when the segmented control that represents the time length of the chart is changed
    @IBAction func graphDurationSegmentedControlChanged(_ sender: Any) {
        let graphDuration = self.graphDurationSegmentedControl.titleForSegment(at: self.graphDurationSegmentedControl.selectedSegmentIndex)
        // Package SwiftUICharts has a bug where if the chart is interacted with but isn't loaded in yet, the application fatally crashes
        self.view.isUserInteractionEnabled = false
        
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
    
    /// Assigns calls a request to the API which in turn loads data into the chart and page labels
    func generateChartData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        // Validate watchlist exists
        guard let portfolio = self.portfolio else {
            return
        }
        
        // Create queries for API request
        let tickers = Algorithm.getTickerQuery(portfolio)
        let previousOpenDate = Algorithm.getPreviousOpenDateQuery(unit: unit, unitsBackwards: unitsBackwards)
        
        indicator.startAnimating()
        
        // Calls the API which in turn provides data to the chart and labels
        self.requestTickerWebData(tickers: tickers, startDate: previousOpenDate, interval: interval, onlyUpdateGraph: onlyUpdateGraph)
    }
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data, and loads them into the chart and page labels
    func requestTickerWebData(tickers: String, startDate: String, interval: String, onlyUpdateGraph: Bool) {
        // Generate URL from components
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
                
                // Remove previous holdings data
                self.holdings = []
                
                if tickers.contains(",") {
                    // Multiple ticker request
                    let tickerResponse = try decoder.decode(DecodedTickerArray.self, from: data!)
                    
                    // For every ticker with data returned, create a new Holding with its data
                    for ticker in tickerResponse.tickerArray {
                        if let holding = Algorithm.createHoldingFromTickerResponse(ticker) {
                            self.holdings.append(holding)
                        }
                    }
                }
                else {
                    // Single ticker request
                    let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                    
                    if let holding = Algorithm.createHoldingFromTickerResponse(tickerResponse) {
                        self.holdings.append(holding)
                    }
                }
                // Add the purchase data for each holding created
                let coreHoldings = self.portfolio?.holdings?.allObjects as! [CoreHolding]
                Algorithm.transferPurchasesFromCoreToHoldings(coreHoldings: coreHoldings, holdings: self.holdings)
                
                // If no holdings were created from the API request, don't run the following code because it'll crash
                if self.holdings.count > 0 {
                    DispatchQueue.main.async {
                        // Update chart and tableview
                        self.chartData.data = Algorithm.getChartPlots(holdings: self.holdings)
                        self.chartData.updateColour()
                        self.view.isUserInteractionEnabled = true
                        
                        if !onlyUpdateGraph {
                            // If the entire page is being updated
                            
                            self.holdingsTableView.reloadData()
                            
                            let totalReturnInDollars = Algorithm.getTotalReturnInDollars(self.holdings)
                            let totalReturnInPercentage = Algorithm.getTotalReturnInPercentage(self.holdings)
                            let totalEquities = Algorithm.roundToTwo(Algorithm.getTotalEquities(self.holdings))
                            
                            // Total return label
                            self.totalReturnLabel.text = Algorithm.getReturnDescription(returnInDollars: totalReturnInDollars, returnInPercentage: totalReturnInPercentage)
                            self.totalReturnLabel.textColor = Algorithm.getReturnColour(totalReturnInDollars)
                            
                            // Total equities label
                            self.totalEquitiesLabel.text = "$\(totalEquities)"
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
    
    @IBAction func handlePinch(_ sender: Any) {
        guard let recognizer = sender as? UIPinchGestureRecognizer else {
            return
        }
        let pinchedChartRange = Algorithm.getPinchedChartRange(scale: recognizer.scale, touchCoords: recognizer.location(in: self.view), chartPlotCount: self.chartData.data.count)
        self.chartData.data = Array(self.chartData.data[pinchedChartRange])
    }
    
    /// Calls when a segue is triggered
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewHolding" {
            let destination = segue.destination as! HoldingViewController
            destination.holding = self.holdings[self.holdingsTableView.indexPathForSelectedRow!.row]
        }
    }

}

// MARK: - TableView Methods Extension

extension PortfolioViewController {
    
    /// Returns how many sections the TableView has
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: holdings in portfolio
        return 1
    }
    
    /// Returns the number of rows in any given section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.holdings.count
    }
    
    /// Creates the cells and contents of the TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: holdings in portfolio
        
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath) as! PortfolioHoldingTableViewCell
        let holding = self.holdings[indexPath.row]
        
        let shares = Algorithm.roundToTwo(holding.getSharesOwned())
        let totalReturnInDollars = holding.getReturnInDollars()
        let totalReturnInPercentage = holding.getReturnInPercentage()
        let shownEquity = Algorithm.roundToTwo(holding.getEquity())
        
        // Ticker label
        holdingCell.tickerLabel?.text = holding.ticker
        holdingCell.tickerLabel?.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
        
        // Shares label
        holdingCell.sharesLabel?.text = "\(shares) Shares"
        holdingCell.sharesLabel?.font = CustomFont.setItalicBodyFont()
        
        // Total return label
        holdingCell.returnInDollarsAndPercentage?.text = Algorithm.getReturnDescription(returnInDollars: totalReturnInDollars, returnInPercentage: totalReturnInPercentage)
        holdingCell.returnInDollarsAndPercentage?.font = CustomFont.setBodyFont()
        holdingCell.returnInDollarsAndPercentage?.textColor = Algorithm.getReturnColour(totalReturnInDollars)
        
        // Equity label
        holdingCell.equityLabel?.text = "$\(shownEquity)"
        holdingCell.equityLabel?.font = CustomFont.setBodyFont()
        
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

extension PortfolioViewController {

    /// Adds the SwiftUI chart view as a child to PortfolioViewController
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
