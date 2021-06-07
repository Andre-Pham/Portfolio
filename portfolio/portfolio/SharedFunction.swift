//
//  SharedFunction.swift
//  portfolio
//
//  Created by Andre Pham on 7/6/21.
//

import UIKit

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

}
