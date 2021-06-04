//
//  HoldingViewController.swift
//  portfolio
//
//  Created by Andre Pham on 4/6/21.
//

import UIKit
import SwiftUI

class HoldingViewController: UIViewController {
    
    // MARK: - Properties
    
    // ChartView
    let swiftUIView = ChartView()
    var chartData = ChartData(title: "Title", legend: "Legend", data: [])
    
    // Loading indicators
    var indicator = UIActivityIndicatorView()
    
    // Other properties
    var holding: Holding?
    
    // MARK: - Outlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var graphDurationSegmentedControl: UISegmentedControl!
    
    // Stack views
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var graphDurationStackView: UIStackView!
    @IBOutlet weak var currentPriceStackView: UIStackView!
    @IBOutlet weak var todaysChangesStackView: UIStackView!
    
    // Labels
    @IBOutlet weak var currentPriceDescriptionLabel: UILabel!
    @IBOutlet weak var currentPriceLabel: UILabel!
    @IBOutlet weak var todaysChangeDescriptionLabel: UILabel!
    @IBOutlet weak var todaysChangeLabel: UILabel!
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add margins to the stack views
        self.rootStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 0)
        self.graphDurationStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.currentPriceStackView.directionalLayoutMargins = .init(top: 25, leading: 15, bottom: 0, trailing: 15)
        self.todaysChangesStackView.directionalLayoutMargins = .init(top: 10, leading: 15, bottom: 0, trailing: 15)
        self.rootStackView.isLayoutMarginsRelativeArrangement = true
        self.graphDurationStackView.isLayoutMarginsRelativeArrangement = true
        self.currentPriceStackView.isLayoutMarginsRelativeArrangement = true
        self.todaysChangesStackView.isLayoutMarginsRelativeArrangement = true

        // Add the chart to the view
        self.addSubSwiftUIView(swiftUIView, to: view, chartData: self.chartData)
        
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
        self.scrollView.alwaysBounceVertical = true
        
        // Fonts
        self.currentPriceDescriptionLabel.font = CustomFont.setBodyFont().bold
        self.todaysChangeDescriptionLabel.font = CustomFont.setBodyFont().bold
        
        // Title
        self.title = self.holding?.ticker
        
        // Current price label
        if let currentPrice = self.holding?.currentPrice {
            self.currentPriceLabel.text = ("$\(abs(Algorithm.roundToTwo(currentPrice)))")
        }
        self.currentPriceLabel.font = CustomFont.setBodyFont()
        
        // Change since open label
        if let change = self.holding?.getDayReturnInPercentage() {
            self.todaysChangeLabel.text = Algorithm.getReturnInPercentageDescription(change)
            self.todaysChangeLabel.textColor = Algorithm.getReturnColour(change)
        }
        self.todaysChangeLabel.font = CustomFont.setBodyFont()
        
        // Generate content
        self.requestTickerWebData(unitsBackwards: 1, unit: .day, interval: "5min", onlyUpdateGraph: false)
    }
    
    /// Calls when the segmented control that represents the time length of the chart is changed
    @IBAction func graphDurationSegmentedControlChanged(_ sender: Any) {
        let graphDuration = self.graphDurationSegmentedControl.titleForSegment(at: self.graphDurationSegmentedControl.selectedSegmentIndex)
        self.chartData.data = []
        switch graphDuration {
        case "24H":
            self.requestTickerWebData(unitsBackwards: 1, unit: .day, interval: "5min", onlyUpdateGraph: false)
            break
        case "1W":
            self.requestTickerWebData(unitsBackwards: 7, unit: .day, interval: "30min", onlyUpdateGraph: true)
            break
        case "1M":
            self.requestTickerWebData(unitsBackwards: 1, unit: .month, interval: "1day", onlyUpdateGraph: true)
            break
        case "1Y":
            self.requestTickerWebData(unitsBackwards: 1, unit: .year, interval: "1week", onlyUpdateGraph: true)
            break
        case "5Y":
            self.requestTickerWebData(unitsBackwards: 5, unit: .year, interval: "1month", onlyUpdateGraph: true)
            break
        case "10Y":
            self.requestTickerWebData(unitsBackwards: 10, unit: .year, interval: "1month", onlyUpdateGraph: true)
            break
        default:
            break
        }
    }
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data, and loads them into the chart and page labels
    func requestTickerWebData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        guard let ticker = self.holding?.ticker else {
            return
        }
        let startDate = Algorithm.getPreviousOpenDateQuery(unit: unit, unitsBackwards: unitsBackwards)
        
        // Generate URL from components
        let requestURLComponents = Algorithm.getRequestURLComponents(tickers: ticker, interval: interval, startDate: startDate)
        
        // Ensure URL is valid
        guard let requestURL = requestURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        indicator.startAnimating()
        
        // Occurs on a new thread
        let task = URLSession.shared.dataTask(with: requestURL) {
            (data, response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            // Parse data
            do {
                let decoder = JSONDecoder()
            
                let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                // Create a new holding with the returned data
                if let holding = Algorithm.createHoldingFromTickerResponse(tickerResponse) {
                    self.holding = holding
                }

                DispatchQueue.main.async {
                    // Update chart and tableview
                    if let holding = self.holding {
                        self.chartData.data = Algorithm.getChartPlots(holdings: [holding])
                    }
                    self.chartData.updateColour()
                    
                    self.indicator.stopAnimating()
                }
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }

}

extension HoldingViewController {

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