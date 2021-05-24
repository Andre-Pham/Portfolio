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

}
