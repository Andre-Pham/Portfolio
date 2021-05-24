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

}
