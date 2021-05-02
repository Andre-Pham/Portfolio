//
//  SearchNewHoldingTableViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class SearchNewHoldingTableViewController: UITableViewController {
    
    var searchResultsHoldings = [Holding]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestSearchTickerWebData(searchText: "NDQ")
    }

    func requestSearchTickerWebData(searchText: String) {
        // https://api.twelvedata.com/symbol_search?symbol=NDQ&source=docs
        
        // Form URL from different components
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/symbol_search"
        requestURLComponents.queryItems = [
            URLQueryItem(
                name: "symbol",
                value: searchText
            ),
            URLQueryItem(
                name: "source",
                value: "docs"
            )
        ]
        
        // Ensure URL is valid
        guard let requestURL = requestURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        // Occurs on a new thread
        let task = URLSession.shared.dataTask(with: requestURL) {
            (data, response, error) in
            
            // If we have recieved an error message
            if let error = error {
                print(error)
                return
            }
            
            // Parse data
            do {
                let decoder = JSONDecoder()
                let tickerSearchResponse = try decoder.decode(TickerSearchResults.self, from: data!)
                print(tickerSearchResponse.data[0].symbol)
                
                for holding in tickerSearchResponse.data {
                    self.searchResultsHoldings.append(
                        Holding(
                            ticker: holding.symbol,
                            instrument: holding.instrument_name,
                            exchange: holding.exchange,
                            currency: holding.currency
                        )
                    )
                }
            
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }

}
