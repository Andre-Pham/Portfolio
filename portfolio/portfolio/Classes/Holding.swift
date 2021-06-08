//
//  Holding.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class Holding: NSObject {
    
    // MARK: - Properties
    
    // All instances have this
    public var ticker: String?
    
    // Instances that present financial data or a graph have this
    public var prices: [Double] = []
    public var currentPrice: Double?
    public var purchases: [CorePurchase] = [] // Added after instantiation
    
    // Instances that are being added to a watchlist have this
    public var instrument: String?
    public var exchange: String?
    public var currency: String?
    public var instrumentType: String?
    
    // MARK: - Constructors
    
    // Searched holding
    init(ticker: String, instrument: String, exchange: String, currency: String, instrumentType: String) {
        self.ticker = ticker
        self.instrument = instrument
        self.exchange = exchange
        self.currency = currency
        self.instrumentType = instrumentType
    }
    
    // Shown holding
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
            sharesOwned += purchase.shares
        }
        return sharesOwned
    }
    
    func getEquity() -> Double {
        return self.currentPrice!*self.getSharesOwned()
    }
    
    func getReturnInDollars() -> Double {
        var returnInDollars = 0.0
        
        for purchase in self.purchases {
            returnInDollars += self.currentPrice!*purchase.shares - purchase.price*purchase.shares
        }
        
        return returnInDollars
    }
    
    func getReturnInPercentage() -> Double {
        let returnInDollars = self.getReturnInDollars()
        let equity = self.getEquity()
        
        return 100*returnInDollars/(equity - returnInDollars)
    }
    
    func getDayReturnInDollars() -> Double? {
        if let currentPrice = self.currentPrice, let previousPrice = self.prices.last {
            return self.getSharesOwned()*(currentPrice - previousPrice)
        }
        return nil
    }
    
    func getDayReturnInPercentage() -> Double? {
        if let currentPrice = self.currentPrice, let previousPrice = self.prices.last {
            return 100*(currentPrice/previousPrice - 1)
        }
        return nil
    }
    
}
