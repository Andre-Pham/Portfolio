//
//  Constant.swift
//  portfolio
//
//  Created by Andre Pham on 4/6/21.
//

import UIKit

class Constant: NSObject {
    
    // Leading and trailing distance
    static let LEADING = 15
    static let CGF_LEADING = CGFloat(LEADING)
    
    // The text of labels before their actual text is loaded in
    static let DEFAULT_LABEL = "-"
    // The text of labels if there's an error loading the actual text
    static let ERROR_LABEL = "Error"
    
    // API key
    static let API_KEY = "fb1e4d1cdf934bdd8ef247ea380bd80a"
    
    // The keys are the segmented control options for changing the graph's duration
    // The values are the parameters for retrieiving graph plots for the key's duration
    static let GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS: [String: Any] = [
        "24H": ["unitsBackwards": 1, "unit": Calendar.Component.day, "interval": "5min"],
        "1W": ["unitsBackwards": 7, "unit": Calendar.Component.day, "interval": "30min"],
        "1M": ["unitsBackwards": 1, "unit": Calendar.Component.month, "interval": "1day"],
        "1Y": ["unitsBackwards": 1, "unit": Calendar.Component.year, "interval": "1week"],
        "5Y": ["unitsBackwards": 5, "unit": Calendar.Component.year, "interval": "1month"],
        "10Y": ["unitsBackwards": 10, "unit": Calendar.Component.year, "interval": "1month"]
    ]
    
    // Exchanges that are supported that aren't in the US or aren't crypto
    static let OTHER_SUPPORTED_EXCHANGES = [
        "TSX", "TSXV", "NEO", "CSE", "BSE", "NSE", "Euronext", "LSE", "XBER", "XDUS", "FSX",
        "XHAM", "XHAN", "XMUN", "XSTU", "XETR", "BIST"
    ]
    
    // The colour to use if the Assets are not loaded or unwrapped properly
    static let BACKUP_COLOUR = UIColor(red: 0.54, green: 0.54, blue: 0.54, alpha: 1.00)

}
