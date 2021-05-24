//
//  InformationViewController.swift
//  portfolio
//
//  Created by Andre Pham on 25/5/21.
//

import UIKit

class InformationViewController: UIViewController {
    
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var aboutContentLabel: UILabel!
    @IBOutlet weak var disclaimersLabel: UILabel!
    @IBOutlet weak var disclaimersContentLabel: UILabel!
    @IBOutlet weak var softwaresUsedLabel: UILabel!
    @IBOutlet weak var softwaresUsedContentLabel: UILabel!

    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var aboutStackView: UIStackView!
    @IBOutlet weak var disclaimersStackView: UIStackView!
    @IBOutlet weak var softwaresUsedStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let titles = [
            self.aboutLabel,
            self.disclaimersLabel,
            self.softwaresUsedLabel
        ]
        let contents = [
            self.aboutContentLabel,
            self.disclaimersContentLabel,
            self.softwaresUsedContentLabel
        ]
        
        for title in titles {
            title?.font = CustomFont.setSubtitleFont()
        }
        for content in contents {
            content?.font = CustomFont.setBodyFont()
        }
        
        self.rootStackView.directionalLayoutMargins = .init(top: 10, leading: 0, bottom: 20, trailing: 0)
        self.aboutStackView.directionalLayoutMargins = .init(top: 5, leading: 15, bottom: 0, trailing: 15)
        self.disclaimersStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 0, trailing: 15)
        self.softwaresUsedStackView.directionalLayoutMargins = .init(top: 35, leading: 15, bottom: 0, trailing: 15)
        self.rootStackView.isLayoutMarginsRelativeArrangement = true
        self.aboutStackView.isLayoutMarginsRelativeArrangement = true
        self.disclaimersStackView.isLayoutMarginsRelativeArrangement = true
        self.softwaresUsedStackView.isLayoutMarginsRelativeArrangement = true
        
        self.aboutContentLabel.text = "This application is a portfolio tracker for investments such as stocks and cryptocurrencies. You may create a watchlist, and set any \"Owned\" watchlist to your portfolio (swipe row in Watchlists). While the Portfolio and Performance pages are limited to your portfolio, the Dashboard's content may be switched interchangeably with any watchlist you've made.\n\nDeveloped by Andre Pham, Monash student number 31448232."
        
        self.disclaimersContentLabel.text = "Due to limitations of the API, only select stock exchanges are available. For more information, visit twelvedata.com/stocks, the full list of stock exchanges available is found under \"Level A\".\n\nDue to the scope of this application, pages Dashboard, Portfolio and Performance won't work on specific public holidays that occur on business days, as the stock market will be closed, and current prices (nor 24H prices) are retrievable.\n\nDue to the scope of this application, alternate currencies and mixed currencies are not supported. Prices are assumed to be, and presented in the dollar format (\"$\").\n\nDue to limitations of the API and scope of the application, prices will vary based on source of comparison. This is true for all data providers of stock prices, and when compared to Google Finance's prices, mild variations in price occur, as expected. Variation will also occur in a stock's current day, as Google Finance provides the percentage difference since the previous close, considering both post-market prices and pre-market changes, while this application only considers the prices since market open, due to limitations in the API and scope."
        
        self.softwaresUsedContentLabel.text = "TODO: TwelveData and ChartView"
    }
    
}
