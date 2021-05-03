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
    let KEYPATH_TABLEVIEW_HEIGHT = "tableViewHeightKeyPath"
    
    // Other properties
    var shownWatchlist: CoreWatchlist?
    var shownHoldings: [Holding] = []
    
    weak var databaseController: DatabaseProtocol?
    
    let swiftUIView = ChartView()
    var chartData = ChartData(title: "Title", legend: "Legend", data: [])
    
    var indicator = UIActivityIndicatorView()
    
    // MARK: - Outlets
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var dateAndReturnsStackView: UIStackView!
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var holdingsTableViewHeight: NSLayoutConstraint!
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController
        // from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        //self.shownWatchlist = databaseController?.retrievePortfolio()

        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        // Add the line chart to the view
        //self.addChartView()
        addSubSwiftUIView(swiftUIView, to: view, chartData: self.chartData)
        
        // Add margins to the stack views
        rootStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 10)
        rootStackView.isLayoutMarginsRelativeArrangement = true
        dateAndReturnsStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 20)
        dateAndReturnsStackView.isLayoutMarginsRelativeArrangement = true
        
        // TESTING WEB DATA
        
        //self.requestTickerWebData(tickers: "MSFT", startDate: "2021-4-26")
        //self.loadChart()
        // END TESTING WEB DATA
        
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
    
    func loadChart() {
        
        var tickers = ""
        
        let earlierDate = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Date()
        )
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let earlierDateString = formatter.string(from: earlierDate!)
        
        let holdings = self.shownWatchlist?.holdings?.allObjects as! [CoreHolding]
        for holding in holdings {
            tickers += holding.ticker ?? ""
            tickers += ","
        }
        print("-----")
        print(tickers.dropLast())
        print(earlierDateString)
        print("-----")
        indicator.startAnimating()
        self.requestTickerWebData(tickers: String(tickers.dropLast()), startDate: earlierDateString)
        
    }
    
    func requestTickerWebData(tickers: String, startDate: String) {
        // https://api.twelvedata.com/time_series?symbol=MSFT,AMZN&interval=5min&start_date=2021-4-26&timezone=Australia/Sydney&apikey=fb1e4d1cdf934bdd8ef247ea380bd80a
        
        // Form URL from different components
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/time_series"
        requestURLComponents.queryItems = [
            URLQueryItem(
                name: "symbol",
                value: tickers
            ),
            URLQueryItem(
                name: "interval",
                value: "5min"
            ),
            URLQueryItem(
                name: "start_date",
                value: startDate // e.g. "2021-4-26"
            ),
            URLQueryItem(
                name: "timezone",
                value: "Australia/Sydney"
            ),
            URLQueryItem(
                name: "apikey",
                value: "fb1e4d1cdf934bdd8ef247ea380bd80a"
            ),
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
                if tickers.contains(",") {
                    // Multiple ticker request
                    let tickerResponse = try decoder.decode(DecodedTickerArray.self, from: data!)
                    print(tickerResponse.tickerArray)
                    
                    for ticker in tickerResponse.tickerArray {
                        var prices: [Double] = []
                        for stringPrice in ticker.values {
                            if let price = Double(stringPrice.close) {
                                prices.append(price)
                            }
                        }
                        
                        self.shownHoldings.append(
                            Holding(ticker: ticker.meta.symbol, prices: prices, currentPrice: prices.last ?? 0)
                        )
                    }
                    
                }
                else {
                    // Single ticker request
                    let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                    print(tickerResponse.values)
                    print(tickerResponse.meta)
                    
                    var prices: [Double] = []
                    for stringPrice in tickerResponse.values {
                        if let price = Double(stringPrice.close) {
                            prices.append(price)
                        }
                    }
                    
                    self.shownHoldings.append(
                        Holding(ticker: tickerResponse.meta.symbol, prices: prices, currentPrice: prices.last ?? 0)
                    )
                }
                
                if self.shownHoldings.count > 0 {
                    var combinedPrices = [Double](repeating: 0.0, count: self.shownHoldings[0].prices!.count)
                    for holding in self.shownHoldings {
                        for priceIndex in 0..<holding.prices!.count {
                            // API provides values in reverse order -_-
                            let reverseIndex = abs(priceIndex - (holding.prices!.count-1))
                            
                            combinedPrices[reverseIndex] += holding.prices![priceIndex]
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.chartData.data = combinedPrices
                        self.holdingsTableView.reloadData()
                    }
                }
                
                /*
                DispatchQueue.main.async {
                    self.holdingsTableView.reloadData()
                }
                */
            
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.shownWatchlist {
            self.shownWatchlist = portfolio
            self.shownHoldings.removeAll()
            self.loadChart()
            self.holdingsTableView.reloadData()
        }
        
        // Adds an observer which calls observeValue when number of cells changes
        self.holdingsTableView.addObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT, options: .new, context: nil)
        self.holdingsTableView.reloadData()
    }
    
    /// Calls before the view disappears on screen
    override func viewWillDisappear(_ animated: Bool) {
        // Remove observer which calls observeValue when number of cells changes
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
                self.holdingsTableViewHeight.constant = newSize.width
            }
        }
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
        //return self.shownWatchlist?.holdings?.count ?? 0
        return self.shownHoldings.count
    }
    
    /// Creates the cells and contents of the TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: holdings in watchlist
        
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
        //let holdings = self.shownWatchlist?.holdings?.allObjects as! [CoreHolding]
        //let holding = holdings[indexPath.row]
        let holding = self.shownHoldings[indexPath.row]
        
        holdingCell.textLabel?.text = holding.ticker
        holdingCell.detailTextLabel?.text = String(holding.currentPrice!)
        
        return holdingCell
    }
    
    /// Returns whether a given section can be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Holdings can be deleted
        return true
    }
    
}

// MARK: - SwiftUI Chart Methods Extension

extension DashboardViewController {
    
    /// Creates then adds a SwiftUI chart to the current view
    /*
    func addChartView() {
        let swiftUIView = ChartView()
        
        let chartData = ChartData(title: "Title", legend: "Legend", data: [100,23,54,32,12,37,7,23,43,-5])
        addSubSwiftUIView(swiftUIView, to: view, chartData: chartData)
        
        // TESTING
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            chartData.data = [5, 10, 100.0]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            chartData.data = [5, 10, 10000.0]
        }
        // TESTING END
    }
    */

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
            chartViewHostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        ]
        NSLayoutConstraint.activate(constraints)

        // Notify the SwiftUI view that it has been moved to DashboardViewController
        chartViewHostingController.didMove(toParent: self)
    }
    
}

// TESTING
/*
extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}
*/
// TESTING END
