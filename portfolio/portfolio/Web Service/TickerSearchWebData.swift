//
//  TickerSearchWebData.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import Foundation

struct TickerSearchResults: Decodable {
    var data: [Data]
}

struct Data: Decodable {
    var symbol: String
    var instrument_name: String
    var exchange: String
    var currency: String
    var instrument_type: String
}
