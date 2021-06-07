//
//  SharedFunction.swift
//  portfolio
//
//  Created by Andre Pham on 7/6/21.
//

import UIKit
import SwiftUI

class SharedFunction: NSObject {
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data
    static func requestTickerWebData(tickers: String, startDate: String, interval: String, indicator: UIActivityIndicatorView, coreWatchlist: CoreWatchlist?, completion: @escaping(Result<[Holding], Error>) -> Void) {
        DispatchQueue.main.async {
            indicator.startAnimating()
        }
        
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
            
            var newHoldings: [Holding] = []
            
            DispatchQueue.main.async {
                indicator.stopAnimating()
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
                            newHoldings.append(holding)
                        }
                    }
                }
                else {
                    // Single ticker request
                    let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                    
                    // Create a new holding with the returned data
                    if let holding = Algorithm.createHoldingFromTickerResponse(tickerResponse) {
                        newHoldings.append(holding)
                    }
                }
                // Arrange the holdings in alphabetical order
                Algorithm.arrangeHoldingsAlphabetically(&newHoldings)
                // Add the purchase data for each holding created
                let coreHoldings = coreWatchlist?.holdings?.allObjects as! [CoreHolding]
                Algorithm.transferPurchasesFromCoreToHoldings(coreHoldings: coreHoldings, holdings: newHoldings)
                
                completion(.success(newHoldings))
            }
            catch let err {
                completion(.failure(err))
            }
        }
        
        task.resume()
    }
    
    static func setUpLoadingIndicator(indicator: UIActivityIndicatorView, view: UIView) {
        // Setup indicator
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        // Centres the loading indicator
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    /// Adds the SwiftUI chart view as a child to the current ViewController
    static func addSubSwiftUIView<Content>(_ swiftUIView: Content, to view: UIView, chartData: ChartData, viewController: UIViewController, stackView: UIStackView) where Content : View {
        // SOURCE: https://www.avanderlee.com/swiftui/integrating-swiftui-with-uikit/
        // AUTHOR: ANTOINE VAN DER LEE - https://www.avanderlee.com/
        
        // Create SwiftUI view (chartViewHostingController) and add it as a child to DashboardViewController
        let chartViewHostingController = UIHostingController(rootView: swiftUIView.environmentObject(chartData))
        viewController.addChild(chartViewHostingController)

        // Insert the SwiftUI view without overlap
        stackView.insertArrangedSubview(chartViewHostingController.view, at: 0)

        // Add constraints to the SwiftUI view
        chartViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            chartViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chartViewHostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.40)
        ]
        NSLayoutConstraint.activate(constraints)

        // Notify the SwiftUI view that it has been moved to DashboardViewController
        chartViewHostingController.didMove(toParent: viewController)
    }

}
