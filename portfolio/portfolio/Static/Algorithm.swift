//
//  Algorithm.swift
//  portfolio
//
//  Created by Andre Pham on 11/5/21.
//

import UIKit

class Algorithm: NSObject {
    // These are functions that are either really specific calculations/algorithms
    // that are better encapsulated to be used as one line, or are repeated enough to
    // be made as a static function
    
    // MARK: - Description Algorithms
    
    /// Returns a number rounded to 2 decimal places
    static func roundToTwo(_ number: Double) -> Double {
        return round(number * 100)/100.0
    }
    
    /// Returns "+" or "-" to be used as a prefix, based on if a number is positive or negative
    static func getPrefix(_ number: Double) -> String {
        if number < 0 {
            return "-"
        }
        return "+"
    }
    
    /// Returns the colour to represent a gain or loss in money
    static func getReturnColour(_ number: Double) -> UIColor {
        if number < 0 {
            return UIColor(named: "Red1") ?? Constant.BACKUP_COLOUR
        }
        return UIColor(named: "Green1") ?? Constant.BACKUP_COLOUR
    }
    
    /// Generates the description to represent a return in the format "+ $500 (100%)"
    static func getReturnDescription(returnInDollars: Double, returnInPercentage: Double) -> String {
        let prefix = Algorithm.getPrefix(returnInDollars)
        let shownReturnInDollars = Algorithm.roundToTwo(abs(returnInDollars))
        let shownReturnInPercentage = Algorithm.roundToTwo(abs(returnInPercentage))
        return "\(prefix) $\(shownReturnInDollars) (\(shownReturnInPercentage)%)"
    }
    
    /// Generates a description to represent a return in the format "+ $500"
    static func getReturnInDollarsDescription(_ returnInDollars: Double) -> String {
        let prefix = Algorithm.getPrefix(returnInDollars)
        let shownReturnInDollars = Algorithm.roundToTwo(abs(returnInDollars))
        return "\(prefix) $\(shownReturnInDollars)"
    }
    
    /// Generates a description to rpresent a return in the format "+ 100%"
    static func getReturnInPercentageDescription(_ returnInPercentage: Double) -> String {
        let prefix = Algorithm.getPrefix(returnInPercentage)
        let shownReturnInPercentage = Algorithm.roundToTwo(abs(returnInPercentage))
        return "\(prefix) \(shownReturnInPercentage)%"
    }
    
    /// Generates a description for the current date in the format "Tuesday, June 8"
    static func getCurrentDateDescription() -> String {
        // Generate current date as a string
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        var currentDateFormatted = formatter.string(from: currentDate)
        
        // Remove year from the current date string
        formatter.dateFormat = "yyyy"
        let currentYearFormatted = formatter.string(from: currentDate)
        currentDateFormatted = currentDateFormatted.replacingOccurrences(of: ", \(currentYearFormatted)", with: "")
        
        return currentDateFormatted
    }
    
    /// Generates a custom font size specifically for the Annual Average Return cell in Performance, based on number
    static func getAdjustedLargeFontSize(_ number: Double) -> Double {
        var sizeReduction = 0.0
        if abs(number) >= 100 {
            sizeReduction += number*0.0009 + 2.5556
        }
        return CustomFont.LARGE_SIZE - sizeReduction
    }
    
    // MARK: - API Request Algorithms
    
    /// Concatenate tickers in the format to be used as a query for the API request
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
    
    /// Get the previous makret open's date and format it to be used as a query for the API request
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
    
    /// Form the url for the API request using the parameters as components
    static func getPricesRequestURLComponents(tickers: String, interval: String, startDate: String) -> URLComponents {
        // EXAMPLE: https://api.twelvedata.com/time_series?symbol=MSFT,AMZN&interval=5min&start_date=2021-4-26&timezone=Australia/Sydney&apikey=fb1e4d1cdf934bdd8ef247ea380bd80a
        
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
    
    static func getSearchRequestURLComponents(searchText: String) -> URLComponents {
        // EXAMPLE: https://api.twelvedata.com/symbol_search?symbol=NDQ&source=docs
        
        // Form URL from different components
        var requestURLComponents = URLComponents()
        requestURLComponents.scheme = "https"
        requestURLComponents.host = "api.twelvedata.com"
        requestURLComponents.path = "/symbol_search"
        requestURLComponents.queryItems = [
            URLQueryItem(
                name: "symbol",
                value: searchText
            ),
            URLQueryItem(
                name: "source",
                value: "docs"
            )
        ]
        
        return requestURLComponents
    }
    
    // MARK: - API Response Algorithms
    
    /// Retrieve the prices within the decoded API response for a single holding, the last price in the array is the current price
    static func getPrices(_ tickerResponse: Ticker) -> [Double]? {
        var prices: [Double] = []
        var currentPrice: Double? = nil
        for stringPrice in tickerResponse.values {
            if let price = Double(stringPrice.open) {
                if price == 0 {
                    // If the price is very low (e.g. Doge Coin) the price is reported as 0 by the API, which breaks the program - 0.00001 is the smallest reportable number by the API
                    prices.append(0.00001)
                }
                else {
                    prices.append(price)
                }
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
    
    /// Using data retrieved from the decoded API response, create an instance of a Holding with said data
    static func createHoldingFromTickerResponse(_ tickerResponse: Ticker) -> Holding? {
        // Get price data in Double type retreived from API
        if let allPrices = Algorithm.getPrices(tickerResponse) {
            let prices = Array(allPrices.dropLast())
            let currentPrice = allPrices.last
            
            return Holding(ticker: tickerResponse.meta.symbol, prices: prices, currentPrice: currentPrice!)
        }
        return nil
    }
    
    /// Combines the prices of all the holdings to generate graph plots in percentage
    static func getChartPlots(holdings: [Holding]) -> [Double] {
        // Find how many prices to plot
        var num_prices = 0
        for holding in holdings {
            if holding.prices.count > num_prices {
                num_prices = holding.prices.count
            }
        }
        
        // Merge all the prices of the holdings to create the single graph
        var combinedPlots = [Double](repeating: 0.0, count: num_prices)
        for holding in holdings {
            let holdingPercentages = holding.convertPricesToPercentages()
            for priceIndex in 0..<holdingPercentages.count {
                // API provides values in reverse order
                let reverseIndex = abs(priceIndex - (holdingPercentages.count-1))
                
                combinedPlots[reverseIndex] += holdingPercentages[priceIndex]
            }
        }
        
        return combinedPlots
    }
    
    /// Transfer purchase information from Core Data to Holding instances
    static func transferPurchasesFromCoreToHoldings(coreHoldings: [CoreHolding], holdings: [Holding]) {
        // Add the purchase data for each holding created
        for coreHolding in coreHoldings {
            for holding in holdings {
                if coreHolding.ticker == holding.ticker {
                    holding.purchases = coreHolding.purchases?.allObjects as! [CorePurchase]
                }
            }
        }
    }
    
    // MARK: - Finance Algorithms
    
    /// Get the return in dollars of an array of owned Holdings since their purchase dates
    static func getTotalReturnInDollars(_ holdings: [Holding]) -> Double {
        var totalReturnInDollars = 0.0
        for holding in holdings {
            totalReturnInDollars += holding.getReturnInDollars()
        }
        return totalReturnInDollars
    }
    
    /// Get the total equities (total dollar value) of an array of owned Holdings
    static func getTotalEquities(_ holdings: [Holding]) -> Double {
        var totalEquities = 0.0
        for holding in holdings {
            totalEquities += holding.getEquity()
        }
        return totalEquities
    }
    
    /// Get the return in percentage of an array of owned Holdings since their purchase dates
    static func getTotalReturnInPercentage(_ holdings: [Holding]) -> Double {
        let totalReturnInDollars = Algorithm.getTotalReturnInDollars(holdings)
        let totalEquities = Algorithm.getTotalEquities(holdings)
        return 100*(totalEquities/(totalEquities - totalReturnInDollars) - 1)
    }
    
    /// Get the average annual return of an array of owned Holdings based on performance
    static func getAverageUnitReturnInPercentage(holdings: [Holding], daysInUnit: Double) -> Double {
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
        let unitsBetweenFirstDate = Double(daysBetweenFirstDate)/daysInUnit
        
        // Derived from initialInvestment*averageAnnualReturn^years = totalEquity
        return 100*(pow((totalEquity/totalInitialEquities), (1/unitsBetweenFirstDate)) - 1)
    }
    
    /// Get the return in dollars of an array of owned Holdings for the past 24H
    static func getDayReturnInDollars(_ holdings: [Holding]) -> Double {
        var dayReturnInDollars = 0.0
        for holding in holdings {
            if let holdingDayReturnInDollars = holding.getDayReturnInDollars() {
                dayReturnInDollars += holdingDayReturnInDollars
            }
        }
        return dayReturnInDollars
    }
    
    /// Get the return in percentage of an array of owned Holdings for the past 24H
    static func getDayReturnInPercentage(_ holdings: [Holding]) -> Double {
        let totalEquity = Algorithm.getTotalEquities(holdings)
        let dayReturnInDollars = Algorithm.getDayReturnInDollars(holdings)
        return 100*((totalEquity/(totalEquity - dayReturnInDollars) - 1))
    }
    
    /// Gets the return in percentage of an array of unowned Holdings for the past 24H
    static func getDayGrowthInPercentage(_ holdings: [Holding]) -> Double {
        var dayReturnInPercentage = 0.0
        for holding in holdings {
            if let percentageReturn = holding.getDayReturnInPercentage() {
                dayReturnInPercentage += percentageReturn
            }
        }
        return dayReturnInPercentage
    }
    
    // MARK: - Watchlist Algorithms
    
    /**
     Depending on the arguments provided, return the best/worst holding from an array of holdings, based on their return
     in percentage/dollars
     */
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
    
    /**
     Returns an array of holdings ranked from worst to best in terms of return in percentage/dollars, depending on arguments.
     Holdings are ranked from wost to best so their indices match their score i.e. first index = 0, first holding has score of 0
     */
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
    
    /**
     Returns two nested arrays based off an array of holdings, the first being the 3 "winner" holdings and the second being
     the 3 "loser" holdings, where ranks are based on merging the ranks of the holdings from their return in dollars and return
     in percentage
     */
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
            // AUTHOR: Dan Beaulieu - https://stackoverflow.com/users/1664443/dan-beaulieu
            let rankedHoldings = scores.sorted(by: {$0.1 < $1.1})
            
            for i in 0...2 {
                if holdings.count > i {
                    winnerHoldings.append(rankedHoldings[i].key)
                    loserHoldings.append(rankedHoldings[holdings.count-i-1].key)
                }
            }
            
            // Winner holdings can't be negative, loser holdings can't be positive
            winnerHoldings = winnerHoldings.filter() { $0.getReturnInDollars() > 0 }
            loserHoldings = loserHoldings.filter() { $0.getReturnInDollars() < 0 }
            
            return [winnerHoldings, loserHoldings]
        }
        return [[], []]
    }
    
    /// Mutates an array of Holdings to be alphabetically in order
    static func arrangeHoldingsAlphabetically(_ holdings: inout [Holding]) {
        holdings.sort {
            if let ticker1 = $0.ticker, let ticker2 = $1.ticker {
                return ticker1 < ticker2
            }
            return false
        }
    }
    
    /// Mutates an array of CoreHoldings to be in alphabetical order
    static func arrangeCoreHoldingsAlphabetically(_ coreHoldings: inout [CoreHolding]) {
        coreHoldings.sort {
            if let ticker1 = $0.ticker, let ticker2 = $1.ticker {
                return ticker1 < ticker2
            }
            return false
        }
    }
    
    /// Mutates an array of CorePurchases to be in order of date, from most recent to least recent
    static func arrangeCorePurchases(_ corePurchases: inout [CorePurchase]) {
        corePurchases.sort {
            if let date1 = $0.date, let date2 = $1.date {
                return date1 > date2
            }
            return false
        }
    }
    
    // MARK: - Gesture Algorithms
    
    /// Generate the range of chart plot values to keep based on how much the and horizontally where user has pinched
    static func getPinchedChartRange(scale: CGFloat, touchCoords: CGPoint, chartPlotCount: Int) -> ClosedRange<Int> {
        // current number of plots * multiplier = new number of plots (minimum of 2 remaining)
        var multiplier = -0.0833*Double(scale) + 1.0833
        if multiplier > 1.0 {
            return 0...chartPlotCount - 1
        }
        if multiplier < 0.0 {
            multiplier = 0.0
        }
        var newChartPlotCount = Double(chartPlotCount)*multiplier
        if newChartPlotCount < 2.0 {
            newChartPlotCount = 2.0
        }
        
        // Middle index is the index in the array relative to the horizontal pinch position
        let screenWidth = UIScreen.main.bounds.width
        let middleIndex = Int(Double(chartPlotCount)*(Double(touchCoords.x)/Double(screenWidth)))
        
        var leftIndex = middleIndex - Int(floor(newChartPlotCount/2))
        if leftIndex < 0 {
            leftIndex = 0
        }
        var rightIndex = middleIndex + Int(floor(newChartPlotCount/2))
        if rightIndex > chartPlotCount - 1 {
            rightIndex = chartPlotCount - 1
        }
        return leftIndex...rightIndex
    }
    
}
