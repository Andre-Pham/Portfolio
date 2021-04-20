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
    
    // Optional
    var sharesOwned: Double?
    var purchasePrice: Double?
    var purchaseDate: String?
    
    // Not owned holding
    init(ticker: String, dates: [String], prices: [Double], currentPrice: Double) {
        self.ticker = ticker
        self.dates = dates
        self.prices = prices
        self.currentPrice = currentPrice
    }
    
    // Owned holding
    init(ticker: String, dates: [String], prices: [Double], currentPrice: Double, sharesOwned: Double, purchasePrice: Double, purchaseDate: String) {
        self.ticker = ticker
        self.dates = dates
        self.prices = prices
        self.currentPrice = currentPrice
        self.sharesOwned = sharesOwned
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
    }
    
    func getEquity() -> Double {
        // MODIFY TO SUPPORT MULTIPLE PURCHASE DATES
        return self.currentPrice! * self.sharesOwned!
    }
    
    func getGain() -> Double {
        // MODIFY TO SUPPORT MULTIPLE PURCHASE DATES
        return self.currentPrice! * self.sharesOwned! - self.purchasePrice! * self.sharesOwned!
    }
    
}
