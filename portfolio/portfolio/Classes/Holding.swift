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
    var dates: [String]?
    var prices: [Double]?
    var currentPrice: Double?
    
    // Not required
    var purchases: [Purchase] = []
    
    init(ticker: String, dates: [String], prices: [Double], currentPrice: Double) {
        self.ticker = ticker
        self.dates = dates
        self.prices = prices
        self.currentPrice = currentPrice
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
