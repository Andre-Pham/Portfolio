//
//  TickerWebDataModel.swift
//  portfolio
//
//  Created by Andre Pham on 1/5/21.
//

import Foundation

struct Ticker: Decodable {
    var MSFT: TimeSeries
    var AMZN: TimeSeries
}

struct TimeSeries: Decodable {
    var values: [TimeSeriesCloses]
}

struct TimeSeriesCloses: Decodable {
    var close: String
}
