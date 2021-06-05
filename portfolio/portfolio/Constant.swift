//
//  Constant.swift
//  portfolio
//
//  Created by Andre Pham on 4/6/21.
//

import UIKit

class Constant: NSObject {
    
    static let LEADING = 15
    static let CGF_LEADING = CGFloat(LEADING)
    static let DEFAULT_LABEL = "-"
    static let ERROR_LABEL = "Error"
    static let API_KEY = "fb1e4d1cdf934bdd8ef247ea380bd80a"
    static let GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS: [String: Any] = [
        "24H": ["unitsBackwards": 1, "unit": Calendar.Component.day, "interval": "5min"],
        "1W": ["unitsBackwards": 7, "unit": Calendar.Component.day, "interval": "30min"],
        "1M": ["unitsBackwards": 1, "unit": Calendar.Component.month, "interval": "1day"],
        "1Y": ["unitsBackwards": 1, "unit": Calendar.Component.year, "interval": "1week"],
        "5Y": ["unitsBackwards": 5, "unit": Calendar.Component.year, "interval": "1month"],
        "10Y": ["unitsBackwards": 10, "unit": Calendar.Component.year, "interval": "1month"]
    ]

}
