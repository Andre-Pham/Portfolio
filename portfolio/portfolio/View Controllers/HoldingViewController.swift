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
    var chartData = ChartData(title: "Individual Performance", legend: "Change in Percentage (%)", data: [])
    
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
        SharedFunction.addSubSwiftUIView(swiftUIView, to: self.view, chartData: self.chartData, viewController: self, stackView: self.rootStackView)
        
        SharedFunction.setUpLoadingIndicator(indicator: self.indicator, view: self.view)
        
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
        guard let graphDuration = self.graphDurationSegmentedControl.titleForSegment(at: self.graphDurationSegmentedControl.selectedSegmentIndex) else {
            return
        }
        // Clear chart data
        self.chartData.data = []

        if Constant.GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS.keys.contains(graphDuration) {
            let params = Constant.GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS[graphDuration] as! Dictionary<String, Any>
            self.requestTickerWebData(
                unitsBackwards: params["unitsBackwards"] as! Int,
                unit: params["unit"] as! Calendar.Component,
                interval: params["interval"] as! String,
                onlyUpdateGraph: true
            )
        }
        else {
            fatalError("Constant.GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS doesn't have matching keys to segmented control")
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
            
                let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                // Create a new holding with the returned data
                if let holding = Algorithm.createHoldingFromTickerResponse(tickerResponse) {
                    self.holding = holding
                }

                DispatchQueue.main.async {
                    // Update chart
                    if let holding = self.holding {
                        self.chartData.data = Algorithm.getChartPlots(holdings: [holding])
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

}
