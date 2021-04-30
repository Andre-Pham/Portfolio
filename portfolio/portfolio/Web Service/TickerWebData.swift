//
//  TickerWebData.swift
//  portfolio
//
//  Created by Andre Pham on 30/4/21.
//

import UIKit

class TickerWebData: NSObject, Decodable {
    
    // MARK: - Properties
    
    // Web service
    var currency: String?
    var exchangeTimezone: String?
    var closeValues = [Double]()
    
    // MARK: - Coding Keys
    
    private enum tickerKeys: String, CodingKey {
        case closeValues = "close"
    }
    
    required init(from decoder: Decoder) throws {
        
        
        /*
        let values = try decoder.container(keyedBy: tickerKeys.self)
        
        do {
            print(type(of: (try values.decode(String.self, forKey: .closeValues))))
            self.currency = try values.decode(String.self, forKey: .closeValues)
        }
        catch {
            self.currency = ""
        }
        */
    }

}
