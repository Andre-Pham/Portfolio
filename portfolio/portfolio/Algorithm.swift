//
//  Algorithm.swift
//  portfolio
//
//  Created by Andre Pham on 11/5/21.
//

import UIKit

class Algorithm: NSObject {
    
    // MARK: - Description Algorithms
    
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
    
    static func getReturnDescription(returnInDollars: Double, returnInPercentage: Double) -> String {
        let prefix = Algorithm.getPrefix(returnInDollars)
        let shownReturnInDollars = Algorithm.roundToTwo(abs(returnInDollars))
        let shownReturnInPercentage = Algorithm.roundToTwo(abs(returnInPercentage))
        return "\(prefix) $\(shownReturnInDollars) (\(shownReturnInPercentage)%)"
    }
    
    static func getReturnInDollarsDescription(_ returnInDollars: Double) -> String {
        let prefix = Algorithm.getPrefix(returnInDollars)
        let shownReturnInDollars = Algorithm.roundToTwo(abs(returnInDollars))
        return "\(prefix) $\(shownReturnInDollars)"
    }
    
    static func getReturnInPercentageDescription(_ returnInPercentage: Double) -> String {
        let prefix = Algorithm.getPrefix(returnInPercentage)
        let shownReturnInPercentage = Algorithm.roundToTwo(abs(returnInPercentage))
        return "\(prefix) \(shownReturnInPercentage)%"
    }
    
    static func getCurrentDateDescription() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        var currentDateFormatted = formatter.string(from: currentDate)
        formatter.dateFormat = "yyyy"
        let currentYearFormatted = formatter.string(from: currentDate)
        currentDateFormatted = currentDateFormatted.replacingOccurrences(of: ", \(currentYearFormatted)", with: "")
        return currentDateFormatted
    }
    
    // MARK: - API Request Algorithms
    
    static func getTickerQuery(_ coreWatchlist: CoreWatchlist) -> String {
        // Generates argument for what tickers data will be retrieved for
        var tickers = ""
        // TODO: Use guard statement to end early if there are no holdings
        let holdings = coreWatchlist.holdings?.allObjects as! [CoreHolding]
        for holding in holdings {
            tickers += holding.ticker ?? ""
            tickers += ","
        }
        // Remove unnecessary extra ","
        return String(tickers.dropLast())
    }
    
    static func getPreviousOpenDateQuery(unit: Calendar.Component, unitsBackwards: Int) -> String {
        // Generates the previous day's date, so we can retrieve intraday prices
        var earlierDate = Calendar.current.date(
            byAdding: unit,
            value: -unitsBackwards,
            to: Date()
        )
        var weekdayNumber = Int(Calendar.current.dateComponents([.weekday], from: earlierDate!).weekday ?? 2)
        while [1, 7].contains(weekdayNumber) {
            // 1: Sunday, 7: Saturday
            // If the data being requested is for Saturday/Sunday, change it to a Friday, because the stockmarket would be closed
            earlierDate = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: earlierDate!
            )
            // One day backwards; 1 (Sun) -> 7 (Sat), 7 (Sat) -> 6 (Fri)
            weekdayNumber -= 1
            if weekdayNumber == 0 {
                weekdayNumber = 7
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: earlierDate!)
    }
    
    static func getRequestURLComponents(tickers: String, interval: String, startDate: String) -> URLComponents {
        // https://api.twelvedata.com/time_series?symbol=MSFT,AMZN&interval=5min&start_date=2021-4-26&timezone=Australia/Sydney&apikey=fb1e4d1cdf934bdd8ef247ea380bd80a
        
        // Form URL from different components
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/time_series"
        requestURLComponents.queryItems = [
            URLQueryItem(name: "symbol", value: tickers),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "start_date", value: startDate), // yyyy-mm-dd
            URLQueryItem(name: "apikey", value: Constant.API_KEY),
        ]
        
        return requestURLComponents
    }
    
    // MARK: - API Response Algorithms
    
    static func getPrices(_ tickerResponse: Ticker) -> [Double]? {
        // Get price data in Double type retreived from API
        var prices: [Double] = []
        var currentPrice: Double? = nil
        for stringPrice in tickerResponse.values {
            if let price = Double(stringPrice.open) {
                prices.append(price)
            }
            if currentPrice == nil {
                currentPrice = Double(stringPrice.close)
            }
        }
        if let currentPrice = currentPrice {
            prices.append(currentPrice)
            return prices
        }
        return nil
    }
    
    static func createHoldingFromTickerResponse(_ tickerResponse: Ticker) -> Holding? {
        // Get price data in Double type retreived from API
        if let allPrices = Algorithm.getPrices(tickerResponse) {
            let prices = Array(allPrices.dropLast())
            let currentPrice = allPrices.last
            
            return Holding(ticker: tickerResponse.meta.symbol, prices: prices, currentPrice: currentPrice!)
        }
        return nil
    }
    
    static func getChartPlots(holdings: [Holding]) -> [Double] {
        // Find how many prices to plot
        var num_prices = 0
        for holding in holdings {
            if holding.prices.count > num_prices {
                num_prices = holding.prices.count
            }
        }
        // Merge all the prices of the holdings to create the single graph
        var combinedPrices = [Double](repeating: 0.0, count: num_prices)
        for holding in holdings {
            let holdingPercentages = holding.convertPricesToPercentages()
            for priceIndex in 0..<holdingPercentages.count {
                // API provides values in reverse order
                let reverseIndex = abs(priceIndex - (holdingPercentages.count-1))
                
                combinedPrices[reverseIndex] += holdingPercentages[priceIndex]
            }
        }
        
        return combinedPrices
    }
    
    // MARK: - Finance Algorithms
    
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
        let totalReturnInDollars = Algorithm.getTotalReturnInDollars(holdings)
        let totalEquities = Algorithm.getTotalEquities(holdings)
        return 100*(totalEquities/(totalEquities - totalReturnInDollars) - 1)
    }
    
    static func getAverageAnnualReturnInPercentage(_ holdings: [Holding]) -> Double {
        let totalEquity = Algorithm.getTotalEquities(holdings)
        var furthestDateBack = Date()
        var totalInitialEquities = 0.0
        for holding in holdings {
            for purchase in holding.purchases {
                totalInitialEquities += purchase.price*purchase.shares
                if let purchaseDate = purchase.date, purchaseDate < furthestDateBack {
                    furthestDateBack = purchaseDate
                }
            }
        }
        
        let daysBetweenFirstDate = Calendar.current.dateComponents([.day], from: furthestDateBack, to: Date()).day!
        let yearsBetweenFirstDate = Double(daysBetweenFirstDate)/365.25
        
        // Derived from initialInvestment*averageAnnualReturn^years = totalEquity
        return 100*(pow((totalEquity/totalInitialEquities), (1/yearsBetweenFirstDate)) - 1)
    }
    
    // MARK: - Watchlist Algorithms
    
    static func getBestOrWorstHolding(_ holdings: [Holding], Best_or_Worst: String, Percentage_or_Dollars: String) -> Holding? {
        if !["Best", "Worst"].contains(Best_or_Worst) || !["Percentage", "Dollars"].contains(Percentage_or_Dollars) {
            fatalError("method getBestOrWorstHolding used incorrectly, invalid parameters given")
        }
        
        if holdings.count > 0 {
            var certainHolding = holdings[0]
            for holding in holdings.dropFirst() {
                if Best_or_Worst == "Best" && Percentage_or_Dollars == "Percentage" && holding.getReturnInPercentage() > certainHolding.getReturnInPercentage() {
                    certainHolding = holding
                }
                else if Best_or_Worst == "Worst" && Percentage_or_Dollars == "Percentage" && holding.getReturnInPercentage() < certainHolding.getReturnInPercentage() {
                    certainHolding = holding
                }
                else if Best_or_Worst == "Best" && Percentage_or_Dollars == "Dollars" && holding.getReturnInDollars() > certainHolding.getReturnInDollars() {
                    certainHolding = holding
                }
                else if Best_or_Worst == "Worst" && Percentage_or_Dollars == "Dollars" && holding.getReturnInDollars() < certainHolding.getReturnInDollars() {
                    certainHolding = holding
                }
            }
            return certainHolding
        }
        return nil
    }
    
    static func getRankedHoldings(_ holdings: [Holding], Percentage_or_Dollars: String) -> [Holding] {
        if !["Percentage", "Dollars"].contains(Percentage_or_Dollars) {
            fatalError("method getBestOrWorstHolding used incorrectly, invalid parameters given")
        }
        var sortedHoldings: [Holding] = []
        for holding in holdings {
            sortedHoldings.append(holding)
        }
        
        // SOURCE: https://www.hackingwithswift.com/example-code/arrays/how-to-sort-an-array-using-sort
        // AUTHOR: Paul Hudson - https://www.hackingwithswift.com/about
        sortedHoldings.sort {
            // From lowest return to highest return
            if Percentage_or_Dollars == "Percentage" {
                return $0.getReturnInPercentage() > $1.getReturnInPercentage()
            }
            else {
                // Dollars
                return $0.getReturnInDollars() > $1.getReturnInDollars()
            }
        }
        
        return sortedHoldings
    }
    
    static func getWinnerAndLoserHoldings(_ holdings: [Holding]) -> [[Holding]] {
        if holdings.count > 0 {
            var winnerHoldings: [Holding] = []
            var loserHoldings: [Holding] = []
            let rankedHoldingsInPercentage = Algorithm.getRankedHoldings(holdings, Percentage_or_Dollars: "Percentage")
            let rankedHoldingsInDollars = Algorithm.getRankedHoldings(holdings, Percentage_or_Dollars: "Dollars")
            var scores = [Holding: Int]()
            for holding in holdings {
                if let percentageScore = rankedHoldingsInPercentage.firstIndex(of: holding), let dollarsScore = rankedHoldingsInDollars.firstIndex(of: holding) {
                    scores[holding] = percentageScore + dollarsScore
                }
            }
            
            // SOURCE: https://stackoverflow.com/questions/25377177/sort-dictionary-by-keys
            // AUTHOR: rks - Dan Beaulieu - https://stackoverflow.com/users/1664443/dan-beaulieu
            let rankedHoldings = scores.sorted(by: {$0.1 < $1.1})
            
            for i in 0...2 {
                if holdings.count > i {
                    winnerHoldings.append(rankedHoldings[i].key)
                    loserHoldings.append(rankedHoldings[holdings.count-i-1].key)
                }
            }
            
            return [winnerHoldings, loserHoldings]
        }
        return [[], []]
    }
    
}
