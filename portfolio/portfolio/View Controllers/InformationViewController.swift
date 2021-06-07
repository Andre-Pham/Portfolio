//
//  InformationViewController.swift
//  portfolio
//
//  Created by Andre Pham on 25/5/21.
//

// https://stackoverflow.com/questions/31668970/is-it-possible-for-uistackview-to-scroll

import UIKit
import SafariServices

class InformationViewController: UIViewController, SFSafariViewControllerDelegate {
    
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var aboutContentLabel: UILabel!
    @IBOutlet weak var disclaimersLabel: UILabel!
    @IBOutlet weak var disclaimersContentLabel: UILabel!
    @IBOutlet weak var softwaresUsedLabel: UILabel!
    @IBOutlet weak var softwaresUsedContentLabel1: UILabel!
    @IBOutlet weak var softwaresUsedContentLabel2: UILabel!
    
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var aboutStackView: UIStackView!
    @IBOutlet weak var disclaimersStackView: UIStackView!
    @IBOutlet weak var softwaresUsedStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SOURCE: https://stackoverflow.com/questions/36730787/set-image-and-title-for-bar-button-item
        // AUTHOR: Olga Nesterenko - https://stackoverflow.com/users/3501300/olga-nesterenko
        // Set up bar button item for notification settings
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.setTitle(" Notifications", for: .normal)
        button.sizeToFit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        button.addTarget(self, action: #selector(self.updateNotificationSettings), for: .touchUpInside)

        let titles = [
            self.aboutLabel,
            self.disclaimersLabel,
            self.softwaresUsedLabel
        ]
        let contents = [
            self.aboutContentLabel,
            self.disclaimersContentLabel,
            self.softwaresUsedContentLabel1,
            self.softwaresUsedContentLabel2
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
        
        self.aboutContentLabel.text = "This application is a portfolio tracker for investments such as stocks and cryptocurrencies. To get started open Watchlists, create a watchlist, and if you set it to \"Owned\" you can set it as your portfolio (swipe left). While the Portfolio and Performance pages are dedicated to your portfolio, the Dashboard's content may be switched interchangeably with any watchlist you've made.\n\nDeveloped by Andre Pham, Monash student number 31448232."
        
        self.disclaimersContentLabel.text = "Due to limitations of the API, only select stock exchanges are available. For more information, visit twelvedata.com/stocks, the full list of stock exchanges available is found under \"Level A\".\n\nDue to the scope of this application, pages Dashboard, Portfolio and Performance won't work on specific public holidays that occur on business days, as the stock market will be closed, and current prices (nor 24H prices) are retrievable.\n\nDue to the scope of this application, alternate currencies and mixed currencies are not supported. Prices are assumed to be, and presented in the dollar format (\"$\").\n\nDue to limitations of the API and scope of the application, prices will vary based on source of comparison. This is true for all data providers of stock prices, and when compared to Google Finance's prices, mild variations in price occur, as expected. Variation will also occur in a stock's current day, as Google Finance provides the percentage difference since the previous close, considering both post-market prices and pre-market changes, while this application only considers the prices since market open, due to limitations in the API and scope."
        
        self.softwaresUsedContentLabel1.text = "To retrieve the latest market information for stocks, cryptocurrencies and other, the Twelve Data API was implemented. This allows the application to make API requests to the webservice, which returns in JSON format the relevant data for processing."
        
        self.softwaresUsedContentLabel2.text = "To present market data in a digestible format, charts were implemented using the ChartView package, available as a public GitHub repository. The package offers simple and clean line charts (as well as other forms of charts) using Apple's SwiftUI framework."
    }
    
    @IBAction func link1Clicked(_ sender: Any) {
        self.openLink(url: "https://twelvedata.com/")
    }
    
    @IBAction func link2Clicked(_ sender: Any) {
        self.openLink(url: "https://github.com/AppPear/ChartView")
    }
    
    func openLink(url: String) {
        if let url = URL(string: url) {
            let safariVC = SFSafariViewController(url: url)
            safariVC.delegate = self
            present(safariVC, animated: true, completion: nil)
        }
    }
    
    @objc func updateNotificationSettings() {
        guard LocalNotification.appDelegate.notificationsEnabled else {
            Popup.displayPopup(title: "Notifications Disabled", message: "You've opted out of recieving notifications. Please enable them in your device's Settings, and refresh the app to continue.", viewController: self)
            
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let settings = storyboard.instantiateViewController(identifier: "setNotificationSettings") as! SetNotificationSettingsViewController
        settings.useAlternateTitle = true
        self.present(settings, animated: true, completion: nil)
    }
    
}
