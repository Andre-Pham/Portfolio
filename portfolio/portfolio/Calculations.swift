//
//  Calculations.swift
//  portfolio
//
//  Created by Andre Pham on 11/5/21.
//

import UIKit

class Calculations: NSObject {
    
    static func roundToTwo(_ number: Double) -> Double {
        return round(number * 100)/100.0
    }
    
    static func getPrefix(_ number: Double) -> String {
        if number < 0 {
            return "-"
        }
        return "+"
    }
    
    static func getReturnColour(_ number: Double) -> UIColor {
        if number < 0 {
            return UIColor(named: "Red1") ?? UIColor.black
        }
        return UIColor(named: "Green1") ?? UIColor.black
    }
    
    static func getTotalReturnInDollars(_ holdings: [Holding]) -> Double {
        var totalReturnInDollars = 0.0
        for holding in holdings {
            totalReturnInDollars += holding.getReturnInDollars()
        }
        return totalReturnInDollars
    }
    
    static func getTotalEquities(_ holdings: [Holding]) -> Double {
        var totalEquities = 0.0
        for holding in holdings {
            totalEquities += holding.getEquity()
        }
        return totalEquities
    }
    
    static func getTotalReturnInPercentage(_ holdings: [Holding]) -> Double {
        let totalReturnInDollars = self.getTotalReturnInDollars(holdings)
        let totalEquities = self.getTotalEquities(holdings)
        return 100*(totalEquities/(totalEquities - totalReturnInDollars) - 1)
    }
    
    static func getAverageAnnualReturnInPercentage(_ holdings: [Holding]) -> Double {
        let totalEquity = self.getTotalEquities(holdings)
        var furthestDateBack = Date()
        var totalInitialEquities = 0.0
        for holding in holdings {
            for purchase in holding.purchases {
                totalInitialEquities += purchase.price*purchase.shares
                if let purchaseDate = purchase.date, purchaseDate < furthestDateBack {
                    furthestDateBack = purchaseDate
                }
            }
        }
        
        let daysBetweenFirstDate = Calendar.current.dateComponents([.day], from: furthestDateBack, to: Date()).day!
        let yearsBetweenFirstDate = Double(daysBetweenFirstDate)/365.25
        
        // Derived from initialInvestment*averageAnnualReturn^years = totalEquity
        return 100*(pow((totalEquity/totalInitialEquities), (1/yearsBetweenFirstDate)) - 1)
    }
    
    static func getCertainHolding(_ holdings: [Holding], Best_or_Worst: String, Percentage_or_Dollars: String) -> Holding? {
        if !["Best", "Worst"].contains(Best_or_Worst) || !["Percentage", "Dollars"].contains(Percentage_or_Dollars) {
            fatalError("method getCertainHolding used incorrectly, invalid parameters given")
        }
        
        if holdings.count > 0 {
            var certainHolding = holdings[0]
            for holding in holdings.dropFirst() {
                if Best_or_Worst == "Best" && Percentage_or_Dollars == "Percentage" && holding.getReturnInPercentage() > certainHolding.getReturnInPercentage() {
                    certainHolding = holding
                }
                else if Best_or_Worst == "Worst" && Percentage_or_Dollars == "Percentage" && holding.getReturnInPercentage() < certainHolding.getReturnInPercentage() {
                    certainHolding = holding
                }
                else if Best_or_Worst == "Best" && Percentage_or_Dollars == "Dollars" && holding.getReturnInDollars() > certainHolding.getReturnInDollars() {
                    certainHolding = holding
                }
                else if Best_or_Worst == "Worst" && Percentage_or_Dollars == "Dollars" && holding.getReturnInDollars() < certainHolding.getReturnInDollars() {
                    certainHolding = holding
                }
            }
            return certainHolding
        }
        return nil
    }
    
}
