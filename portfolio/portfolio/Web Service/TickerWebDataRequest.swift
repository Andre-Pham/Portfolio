//
//  TickerWebDataRequest.swift
//  portfolio
//
//  Created by Andre Pham on 1/5/21.
//

import Foundation

enum requestError: Error {
    case noDataAvailable
    case failedToProcessData
}

struct TickerWebDataRequest {
    
    let requestURL: URL
    let API_KEY = "fb1e4d1cdf934bdd8ef247ea380bd80a"
    
    init(tickerQuery: String) {
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/time_series"
        requestURLComponents.queryItems = [
            URLQueryItem(
                name: "symbol",
                value: tickerQuery
            ),
            URLQueryItem(
                name: "interval",
                value: "5min"
            ),
            URLQueryItem(
                name: "start_date",
                value: "2021-4-26"
            ),
            URLQueryItem(
                name: "timezone",
                value: "Australia/Sydney"
            ),
            URLQueryItem(
                name: "apikey",
                value: self.API_KEY
            ),
        ]
        
        guard let requestURL = requestURLComponents.url else {
            fatalError()
        }
        self.requestURL = requestURL
    }
    
    func requestTickerWebData(completion: @escaping(Result<TimeSeries, requestError>) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: self.requestURL) {
            data, _, _ in
            
            guard let retrievedData = data else {
                completion(.failure(.noDataAvailable))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let tickerResponse = try decoder.decode(Ticker.self, from: retrievedData)
                completion(.success(tickerResponse.MSFT))
            }
            catch {
                completion(.failure(.failedToProcessData))
            }
        }
        
        dataTask.resume()
    }
    
}
