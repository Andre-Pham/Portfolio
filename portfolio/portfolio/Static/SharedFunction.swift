//
//  SharedFunction.swift
//  portfolio
//
//  Created by Andre Pham on 7/6/21.
//

import UIKit
import SwiftUI

class SharedFunction: NSObject {
    // These are functions that are shared by multiple classes
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data
    static func requestTickerWebData(tickers: String, startDate: String, interval: String, indicator: UIActivityIndicatorView, coreWatchlist: CoreWatchlist?, completion: @escaping(Result<[Holding], Error>) -> Void) {
        DispatchQueue.main.async {
            indicator.startAnimating()
        }
        
        // Generate URL from components
        let requestURLComponents = Algorithm.getPricesRequestURLComponents(tickers: tickers, interval: interval, startDate: startDate)
        
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
    
    /// Sets the style and constraints for a loading indicator
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
        // * Multiplier is the amount of the SwiftUI Screen shown - calculated based on fits of different screens
        let h = UIScreen.main.bounds.height
        let multiplier = 0.0000004313*h*h - 0.0012435555*h + 1.1460070991
        let constraints = [
            chartViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chartViewHostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: multiplier)
        ]
        NSLayoutConstraint.activate(constraints)

        // Notify the SwiftUI view that it has been moved to DashboardViewController
        chartViewHostingController.didMove(toParent: viewController)
    }
    
    /// Determines if entires for a purchase is valid, and also displays a popup if they're invalid
    static func purchaseEntriesIsValid(price: Double, shares: Double, viewController: UIViewController) -> Bool {
        var valid = true
        var errorMessage = ""
        if price <= 0 {
            valid = false
            errorMessage.append("The purchase price")
        }
        if shares <= 0 {
            if !valid {
                errorMessage.append(" and the number of shares")
            }
            else {
                errorMessage.append("The number of shares")
            }
            valid = false
        }
        if !valid {
            Popup.displayPopup(title: "Invalid Entries", message: errorMessage+" must be positive. Ensure your entries are valid and try again.", viewController: viewController)
        }
        
        return valid
    }
    
    // SOURCE: https://stackoverflow.com/questions/15746745/handling-an-empty-uitableview-print-a-friendly-message
    // AUTHOR: Frankie - https://stackoverflow.com/users/2047476/frankie
    /// Adds a label indicating to the user that the tableview is empty, if necessary
    static func notifyIfTableViewEmpty(message: String, isEmpty: Bool, tableView: UITableView) {
        if isEmpty {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            messageLabel.text = message
            messageLabel.textColor = UIColor(named: "BlackWhite1")
            messageLabel.alpha = 0.35
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = CustomFont.setFont(size: 25, style: .body, weight: .light)
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel
            tableView.separatorStyle = .none
        }
        else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

}
