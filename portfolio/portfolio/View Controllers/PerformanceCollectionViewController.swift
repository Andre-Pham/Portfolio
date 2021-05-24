//
//  PerformanceCollectionViewController.swift
//  portfolio
//
//  Created by Andre Pham on 23/5/21.
//

import UIKit

private let reuseIdentifier = "Cell"

// https://stackoverflow.com/questions/31735228/how-to-make-a-simple-collection-view-with-swift
class PerformanceCollectionViewController: UICollectionViewController {
    
    let CELL_WIDE = "wideCell"
    let CELL_SINGLE = "singleCell"
    let CELL_TALL = "tallCell"
    var items = ["1", "2", "3", "4", "5", "6", "7"]
    let WIDE_CELL_INDICES = [0]
    let SINGLE_CELL_INDICES = [1, 2, 3, 4]
    let TALL_CELL_INDICES = [5, 6]
    
    let API_KEY = "fb1e4d1cdf934bdd8ef247ea380bd80a"
    
    var portfolio: CoreWatchlist?
    var shownHoldings: [Holding] = []
    // Indicator
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView!.contentInset = UIEdgeInsets(top: 5, left: 15, bottom: 20, right: 15)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 15 // spacing left/right
        layout.minimumLineSpacing = 15 // spacing up/down
        self.collectionView.frame = self.view.frame
        self.collectionView.collectionViewLayout = layout

        
        // Add a loading indicator
        self.indicator.style = UIActivityIndicatorView.Style.large
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.indicator)
        
        // Centres the loading indicator
        NSLayoutConstraint.activate([
            self.indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            self.indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        // Do any additional setup after loading the view.
        self.generateChartData(unitsBackwards: 1, unit: .day, interval: "30min", onlyUpdateGraph: false)
    }
    
    /// Assigns calls a request to the API which in turn loads data into the chart
    func generateChartData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        // Generates argument for what tickers data will be retrieved for
        var tickers = ""
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let databaseController = appDelegate?.databaseController
        self.portfolio = databaseController?.retrievePortfolio()
        let holdings = self.portfolio?.holdings?.allObjects as! [CoreHolding]
        for holding in holdings {
            tickers += holding.ticker ?? ""
            tickers += ","
        }
        // Remove unnecessary extra ","
        tickers = String(tickers.dropLast())
        
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
        let earlierDateFormatted = formatter.string(from: earlierDate!)
        
        // Calls the API which in turn provides data to the chart
        indicator.startAnimating()
        self.requestTickerWebData(tickers: tickers, startDate: earlierDateFormatted, interval: interval, onlyUpdateGraph: onlyUpdateGraph)
    }
    
    /// Calls a TwelveData request for time series prices for ticker(s), as well as other data
    func requestTickerWebData(tickers: String, startDate: String, interval: String, onlyUpdateGraph: Bool) {
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
            URLQueryItem(name: "apikey", value: self.API_KEY),
        ]
        
        // Ensure URL is valid
        guard let requestURL = requestURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        print(requestURL)
        
        // Occurs on a new thread
        let task = URLSession.shared.dataTask(with: requestURL) {
            (data, response, error) in
            
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            // Parse data
            do {
                let decoder = JSONDecoder()
                
                if tickers.contains(",") {
                    // Multiple ticker request
                    let tickerResponse = try decoder.decode(DecodedTickerArray.self, from: data!)
                    
                    // For every ticker with data returned, create a new Holding with its data
                    for ticker in tickerResponse.tickerArray {
                        // Get price data in Double type retrieved from API
                        var prices: [Double] = []
                        for stringPrice in ticker.values {
                            if let price = Double(stringPrice.open) {
                                prices.append(price)
                            }
                        }
                        // Create Holding
                        self.shownHoldings.append(
                            Holding(ticker: ticker.meta.symbol, prices: prices, currentPrice: prices.last ?? 0)
                        )
                    }
                }
                else {
                    // Single ticker request
                    let tickerResponse = try decoder.decode(Ticker.self, from: data!)
                    
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
                    // Create Holding
                    self.shownHoldings.append(
                        Holding(ticker: tickerResponse.meta.symbol, prices: prices, currentPrice: currentPrice ?? 0)
                    )
                }
                // Add the purchase data for each holding created
                let coreHoldings = self.portfolio?.holdings?.allObjects as! [CoreHolding]
                for coreHolding in coreHoldings {
                    for holding in self.shownHoldings {
                        if coreHolding.ticker == holding.ticker {
                            holding.purchases = coreHolding.purchases?.allObjects as! [CorePurchase]
                        }
                    }
                }
                
                // If no holdings were created from the API request, don't run the following code because it'll crash
                if self.shownHoldings.count > 0 {
                    // Find how many prices to plot
                    var num_prices = 0
                    for holding in self.shownHoldings {
                        if holding.prices.count > num_prices {
                            num_prices = holding.prices.count
                        }
                    }
                    // Merge all the prices of the holdings to create the single graph
                    var combinedPrices = [Double](repeating: 0.0, count: num_prices)
                    for holding in self.shownHoldings {
                        let holdingPercentages = holding.convertPricesToPercentages()
                        for priceIndex in 0..<holdingPercentages.count {
                            // API provides values in reverse order
                            let reverseIndex = abs(priceIndex - (holdingPercentages.count-1))
                            
                            combinedPrices[reverseIndex] += holdingPercentages[priceIndex]
                        }
                    }
                    
                    DispatchQueue.main.async {
                        // Do nothing for now
                        self.collectionView.reloadData()
                    }
                }
            }
            catch let err {
                print(err)
            }
        }
        
        task.resume()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_WIDE, for: indexPath as IndexPath) as! WidePerformanceCollectionViewCell
            
            cell.titleLabel.text = "Average\nAnnual\nReturn"
            cell.percentGainLabel.text = "+300.0%"
            //cell.percentGainLabel.text = "\(Calculations.getAverageAnnualReturnInPercentage(shownHoldings))"
            
            cell.titleLabel.font = CustomFont.setSubtitle2Font()
            cell.percentGainLabel.font = CustomFont.setLargeFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            cell.percentGainLabel.textColor = UIColor(named: "Green1")
        
            return cell
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_SINGLE, for: indexPath as IndexPath) as! SinglePerformanceCollectionViewCell
            
            cell.titleLabel.text = "Best Growth"
            cell.tickerLabel.text = "MMMM"
            cell.percentGainLabel.text = "-10.24%"
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            cell.tickerLabel.font = CustomFont.setLarge2Font()
            cell.percentGainLabel.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TALL, for: indexPath as IndexPath) as! TallPerformanceCollectionViewCell
            
            cell.titleLabel.text = "Winners"
            
            cell.tickerLabel1.text = "MMMM"
            cell.gainInPercentageLabel1.text = "-10.24%"
            cell.gainInDollarsLabel1.text = "-$10.24"
            
            cell.tickerLabel2.text = "MMMM"
            cell.gainInPercentageLabel2.text = "-10.24%"
            cell.gainInDollarsLabel2.text = "-$10.24"
            
            cell.tickerLabel3.text = "MMMM"
            cell.gainInPercentageLabel3.text = "-10.24%"
            cell.gainInDollarsLabel3.text = "-$10.24"
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            cell.tickerLabel1.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel1.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel1.font = CustomFont.setBodyFont()
            
            cell.tickerLabel2.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel2.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel2.font = CustomFont.setBodyFont()
            
            cell.tickerLabel3.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel3.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel3.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
        }
        
    }

}

// https://stackoverflow.com/questions/38028013/how-to-set-uicollectionviewcell-width-and-height-programmatically
extension PerformanceCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let width = UIScreen.main.bounds.width - 15*2
            return CGSize(width: width, height: 100)
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let width = (UIScreen.main.bounds.width - 15*3)/2
            return CGSize(width: width, height: 100)
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            let width = (UIScreen.main.bounds.width - 15*3)/2
            return CGSize(width: width, height: 320)
        }
    }
    
}
