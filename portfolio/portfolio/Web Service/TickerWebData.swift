//
//  TickerWebData.swift
//  portfolio
//
//  Created by Andre Pham on 1/5/21.
//

import Foundation

struct DecodedTickerArray: Decodable {
    var tickerArray: [Ticker]
    
    private struct DynamicCodingKeys: CodingKey {
        
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        // Retrieve close values and meta data
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        var tempArray = [Ticker]()
        
        for key in container.allKeys {
            let decodedObject = try container.decode(Ticker.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)
            tempArray.append(decodedObject)
        }
        
        self.tickerArray = tempArray
    }
}

struct Ticker: Decodable {
    var values: [TimeSeriesCloses]
    var meta: MetaData
}

struct MetaData: Decodable {
    var symbol: String
    var currency: String
}

struct TimeSeriesCloses: Decodable {
    var open: String
    var close: String
}
