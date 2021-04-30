//
//  TickerRootWebData.swift
//  portfolio
//
//  Created by Andre Pham on 30/4/21.
//

import UIKit

class TickerRootWebData: NSObject, Decodable {
    
    // MARK: - Properties
        
    // Web service
    var tickerData: [TickerWebData]?
    
    // MARK: - Coding Keys
    
    private enum CodingKeys: String, CodingKey {
        case tickerData = "meta"
    }
   
}
