//
//  Holding.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class Holding: NSObject {
    
    // MARK: - Properties
    
    // Required
    var ticker: String?
    var prices: [Double] = []
    var currentPrice: Double?
    
    var instrument: String?
    var exchange: String?
    var currency: String?
    
    
    // Not required
    var purchases: [Purchase] = []
    
    // MARK: - Constructor
    
    // Searched holding
    init(ticker: String, instrument: String, exchange: String, currency: String) {
        self.ticker = ticker
        self.instrument = instrument
        self.exchange = exchange
        self.currency = currency
    }
    
    init(ticker: String, prices: [Double], currentPrice: Double) {
        self.ticker = ticker
        self.prices = prices
        self.currentPrice = currentPrice
    }
    
    // MARK: - Methods
    
    func convertPricesToPercentages() -> [Double] {
        if self.prices.count > 0 {
            let startingPrice = self.prices.last!
            var percentages: [Double] = []
            
            for price in self.prices {
                percentages.append(100*(price/startingPrice - 1))
            }
            
            return percentages
        }
        
        return []
    }
    
    func getSharesOwned() -> Double {
        var sharesOwned = 0.0
        for purchase in self.purchases {
            sharesOwned += purchase.shares ?? 0
        }
        return sharesOwned
    }
    
    func getEquity() -> Double {
        return self.currentPrice!*self.getSharesOwned()
    }
    
    func getReturnInDollars() -> Double {
        var returnInDollars = 0.0
        
        for purchase in self.purchases {
            returnInDollars += self.currentPrice!*purchase.shares! - purchase.price!*purchase.shares!
        }
        
        return returnInDollars
    }
    
    func getReturnInPercentage() -> Double {
        let returnInDollars = self.getReturnInDollars()
        let equity = self.getEquity()
        
        return 100*returnInDollars/(equity - returnInDollars)
    }
    
}
