//
//  DashboardViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

// Scrolling
// SOURCE: https://stevenpcurtis.medium.com/create-a-uistackview-in-a-uiscrollview-e2a959fa061
// Author: Steven Curtis - https://stevenpcurtis.medium.com/

import UIKit
import SwiftUI

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {
    
    // MARK: - Properties
    
    // Constants
    private let KEYPATH_TABLEVIEW_HEIGHT = "contentSize"
    private let CELL_HEIGHT: CGFloat = 30.0
    
    // Cell identifiers
    private let CELL_HOLDING = "holdingCell"
    
    // Segue identifiers
    private let SEGUE_SWITCH_WATCHLIST = "switchWatchlist"
    private let SEGUE_VIEW_HOLDING = "viewHolding"
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // ChartView
    private let swiftUIView = ChartView()
    private var chartData = ChartData(title: "Title", legend: "Change in Percentage (%)", data: [])
    
    // Loading indicators
    private var indicator = UIActivityIndicatorView()
    private var refreshControl = UIRefreshControl()
    
    // Other properties
    private var coreWatchlist: CoreWatchlist?
    private var holdings: [Holding] = []
    private var dontRefresh = false
    
    // MARK: - Outlets
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var holdingsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var graphDurationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Stack views
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var graphDurationStackView: UIStackView!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var dayReturnStackView: UIStackView!
    @IBOutlet weak var totalReturnStackView: UIStackView!
    @IBOutlet weak var holdingsTitleStackView: UIStackView!
    
    // Labels
    @IBOutlet weak var todaysDateLabel: UILabel!
    @IBOutlet weak var dayReturnDescriptionLabel: UILabel!
    @IBOutlet weak var dayReturnLabel: UILabel!
    @IBOutlet weak var totalReturnDescriptionLabel: UILabel!
    @IBOutlet weak var totalReturnLabel: UILabel!
    @IBOutlet weak var holdingsTitleLabel: UILabel!
    @IBOutlet weak var holdingsTitleDetailLabel: UILabel!
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For testing - clears all notifications
        // UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Only add market status notifications if they haven't been set yet
        UNUserNotificationCenter.current().getPendingNotificationRequests {
            (notificationRequests) in
            
            var startMarketStatusNotifications = true
            for notification in notificationRequests {
                print(notification.identifier)
                if notification.identifier.dropLast() == LocalNotification.MARKET_OPEN_NOTIFICATION_IDENTIFIER {
                    startMarketStatusNotifications = false
                    break
                }
            }
            
            DispatchQueue.main.async {
                if startMarketStatusNotifications && LocalNotification.appDelegate.notificationsEnabled {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let settings = storyboard.instantiateViewController(identifier: "setNotificationSettings") as! SetNotificationSettingsViewController
                    self.present(settings, animated: true, completion: nil)
                    // Disable user from swiping down
                    settings.isModalInPresentation = true
                }
            }
        }
        
        // Add the chart to the view
        SharedFunction.addSubSwiftUIView(swiftUIView, to: self.view, chartData: self.chartData, viewController: self, stackView: self.rootStackView)
        
        // Add margins to the stack views
        self.rootStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 0)
        self.graphDurationStackView.directionalLayoutMargins = .init(top: 5, leading: Constant.CGF_LEADING, bottom: 0, trailing: Constant.CGF_LEADING)
        self.dateStackView.directionalLayoutMargins = .init(top: 35, leading: Constant.CGF_LEADING, bottom: 0, trailing: Constant.CGF_LEADING)
        self.dayReturnStackView.directionalLayoutMargins = .init(top: 10, leading: Constant.CGF_LEADING, bottom: 0, trailing: Constant.CGF_LEADING)
        self.totalReturnStackView.directionalLayoutMargins = .init(top: 5, leading: Constant.CGF_LEADING, bottom: 0, trailing: Constant.CGF_LEADING)
        self.holdingsTitleStackView.directionalLayoutMargins = .init(top: 35, leading: Constant.CGF_LEADING, bottom: 5, trailing: Constant.CGF_LEADING)
        self.rootStackView.isLayoutMarginsRelativeArrangement = true
        self.graphDurationStackView.isLayoutMarginsRelativeArrangement = true
        self.dateStackView.isLayoutMarginsRelativeArrangement = true
        self.dayReturnStackView.isLayoutMarginsRelativeArrangement = true
        self.totalReturnStackView.isLayoutMarginsRelativeArrangement = true
        self.holdingsTitleStackView.isLayoutMarginsRelativeArrangement = true
        
        // SOURCE: https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
        // AUTHOR: Ahmad F - https://stackoverflow.com/users/5501940/ahmad-f
        // Add scroll up to refresh
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlChanged(_:)), for: .valueChanged)
        self.scrollView.refreshControl = self.refreshControl
        // Set up loading indicator
        SharedFunction.setUpLoadingIndicator(indicator: self.indicator, view: self.view)
        
        // Fonts
        self.todaysDateLabel.font = CustomFont.setSubtitleFont()
        self.dayReturnDescriptionLabel.font = CustomFont.setBodyFont().bold
        self.dayReturnLabel.font = CustomFont.setBodyFont()
        self.totalReturnDescriptionLabel.font = CustomFont.setBodyFont().bold
        self.totalReturnLabel.font = CustomFont.setBodyFont()
        self.holdingsTitleLabel.font = CustomFont.setSubtitleFont()
        self.holdingsTitleDetailLabel.font = CustomFont.setSubtitleComplementaryFont()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // Link tableView to self
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        // Make it so page scrolls even if all the contents fits on one page
        self.scrollView.alwaysBounceVertical = true
        // Delegate used for checking when user stops scrolling, so page can refresh
        self.scrollView.delegate = self
        
        // Update today's date label
        self.todaysDateLabel.text = Algorithm.getCurrentDateDescription()
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        // Adds observer which calls observeValue when number of tableview cells changes
        self.holdingsTableView.addObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT, options: .new, context: nil)
        self.holdingsTableView.reloadData()
        
        if self.dontRefresh {
            // Because viewing a holding (HoldingViewController) returns the page back to the portfolio, this is cancelled with this special property
            self.dontRefresh = false
            return
        }
        
        // If the user has no portfolio, notify them
        if let portfolioAssigned = databaseController?.portfolioAssigned(), !portfolioAssigned {
            Popup.displayPopup(title: "No Portfolio", message: "You don't have a portfolio set. To get started go to the Watchlists page and create an \"Owned\" watchlist, and make sure to add your holdings. If you have watchlists you'd like to view, select them from the top right \"Switch\" button.", viewController: self)
        }
        
        // If the user has designated a different or new watchlist to be their portfolio, refresh the page's content
        let portfolio = databaseController?.retrievePortfolio()
        if portfolio != self.coreWatchlist || self.coreWatchlist?.holdings?.count != self.holdings.count {
            self.coreWatchlist = portfolio
            self.refresh()
        }
    }
    
    /// Calls before the view disappears on screen
    override func viewWillDisappear(_ animated: Bool) {
        // Removes observer which calls observeValue when number of tableview cells changes
        self.holdingsTableView.removeObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT)
    }
    
    /// Calls when the user scrolls up to refresh
    @objc func refreshControlChanged(_ sender: AnyObject) {
        if !self.scrollView.isDragging {
            self.refresh()
        }
    }
    
    // SOURCE: https://stackoverflow.com/questions/22225207/uirefreshcontrol-jitters-when-pulled-down-and-held
    // AUTHOR: Devin - https://stackoverflow.com/users/968108/devin
    /// Calls when the user stops dragging, used to detect when to refresh after user scrolls up and holds
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.refreshControl.isRefreshing {
            self.refresh()
        }
    }
    
    /// Refreshes the page's content
    func refresh() {
        self.holdings.removeAll()
        self.holdingsTableView.reloadData()
        self.chartData.data = []
        self.chartData.title = self.coreWatchlist?.name ?? Constant.DEFAULT_LABEL
        if self.coreWatchlist?.holdings?.count == 0 {
            self.chartData.title.append(" (Empty)")
        }
        for label in [self.dayReturnLabel, self.totalReturnLabel] {
            label?.text = Constant.DEFAULT_LABEL
            label?.textColor = UIColor(named: "BlackWhite1")
        }
        self.refreshControl.endRefreshing() // End before loading indicator begins
        self.graphDurationSegmentedControl.selectedSegmentIndex = 0
        self.generateChartData(unitsBackwards: 1, unit: .day, interval: "5min", onlyUpdateGraph: false)
    }
    
    /// Calls when triggered by an observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // SOURCE: https://www.youtube.com/watch?v=INkeINPZddo
        // AUTHOR: Divyesh Gondaliya - https://www.youtube.com/channel/UC4pRJw6rNrHuFZV3aOELJkA
        if keyPath == KEYPATH_TABLEVIEW_HEIGHT {
            // Changes TableView height based on number of cells so they're not squished into a nested scroll view
            if let newValue = change?[.newKey] {
                let newSize = newValue as! CGSize
                self.holdingsTableViewHeight.constant = newSize.height
            }
        }
    }
    
    /// Calls when the segmented control that represents the time length of the chart is changed
    @IBAction func graphDurationSegmentedControlChanged(_ sender: Any) {
        guard let graphDuration = self.graphDurationSegmentedControl.titleForSegment(at: self.graphDurationSegmentedControl.selectedSegmentIndex) else {
            return
        }
        // Clear chart data
        self.chartData.data = []

        if Constant.GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS.keys.contains(graphDuration) {
            let params = Constant.GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS[graphDuration] as! Dictionary<String, Any>
            self.generateChartData(
                unitsBackwards: params["unitsBackwards"] as! Int,
                unit: params["unit"] as! Calendar.Component,
                interval: params["interval"] as! String,
                onlyUpdateGraph: true
            )
        }
        else {
            fatalError("Constant.GRAPH_DURATION_SEGMENTED_CONTROL_PARAMS doesn't have matching keys to segmented control")
        }
    }
    
    /// Assigns calls a request to the API which in turn loads data into the chart and page labels
    func generateChartData(unitsBackwards: Int, unit: Calendar.Component, interval: String, onlyUpdateGraph: Bool) {
        // Validate watchlist exists
        guard let watchlist = self.coreWatchlist else {
            return
        }
        
        // Create queries for API request
        let tickers = Algorithm.getTickerQuery(watchlist)
        let previousOpenDate = Algorithm.getPreviousOpenDateQuery(unit: unit, unitsBackwards: unitsBackwards)
        
        // Calls the API which in turn provides data to the chart and labels
        SharedFunction.requestTickerWebData(
            tickers: tickers,
            startDate: previousOpenDate,
            interval: interval,
            indicator: self.indicator,
            coreWatchlist: self.coreWatchlist,
            completion: { [weak self] result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let holdings):
                    self?.holdings = holdings
                    DispatchQueue.main.async {
                        self?.presentData(onlyUpdateGraph: onlyUpdateGraph)
                    }
                }
            }
        )
    }
    
    /// Updates the page with the new content provided from a previous API request
    func presentData(onlyUpdateGraph: Bool) {
        // If no holdings were created from the API request, don't run the following code because it'll crash
        if self.holdings.count > 0 {
            // Update chart and tableview
            self.chartData.data = Algorithm.getChartPlots(holdings: self.holdings)
            
            if let watchlistIsOwned = self.coreWatchlist?.owned, !onlyUpdateGraph {
                // If the entire page is being updated
                
                self.holdingsTableView.reloadData()
                
                if watchlistIsOwned {
                    let dayReturnInDollars = Algorithm.getDayReturnInDollars(self.holdings)
                    let dayReturnInPercentage = Algorithm.getDayReturnInPercentage(self.holdings)
                    let totalReturnInDollars = Algorithm.getTotalReturnInDollars(self.holdings)
                    let totalReturnInPercentage = Algorithm.getTotalReturnInPercentage(self.holdings)
                    
                    // Day's return label
                    self.dayReturnLabel.text = Algorithm.getReturnDescription(returnInDollars: dayReturnInDollars, returnInPercentage: dayReturnInPercentage)
                    self.dayReturnLabel.textColor = Algorithm.getReturnColour(dayReturnInDollars)
                    
                    // Total return label
                    self.totalReturnStackView.isHidden = false
                    self.totalReturnLabel.text = Algorithm.getReturnDescription(returnInDollars: totalReturnInDollars, returnInPercentage: totalReturnInPercentage)
                    self.totalReturnLabel.textColor = Algorithm.getReturnColour(totalReturnInDollars)
                }
                else {
                    // Watchlist isn't owned
                    
                    let dayReturnInPercentage = Algorithm.getDayGrowthInPercentage(self.holdings)
                    
                    // Day's return label
                    self.dayReturnLabel.text = Algorithm.getReturnInPercentageDescription(dayReturnInPercentage) + " Day"
                    self.dayReturnLabel.textColor = Algorithm.getReturnColour(dayReturnInPercentage)
                    
                    // Total return label
                    self.totalReturnStackView.isHidden = true
                }
            }
        }
    }
    
    /// Updates the chart data after pinching to percieve zooming in
    @IBAction func handlePinch(_ sender: Any) {
        guard let recognizer = sender as? UIPinchGestureRecognizer else {
            return
        }
        let pinchedChartRange = Algorithm.getPinchedChartRange(scale: recognizer.scale, touchCoords: recognizer.location(in: self.view), chartPlotCount: self.chartData.data.count)
        self.chartData.data = Array(self.chartData.data[pinchedChartRange])
    }
    
    /// Calls when a segue is triggered
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.SEGUE_SWITCH_WATCHLIST {
            let destination = segue.destination as! SwitchDashboardWatchlistViewController
            // Links self as the delegate to recieve the watchlist to switch to
            destination.switchWatchlistDelegate = self
        }
        else if segue.identifier == self.SEGUE_VIEW_HOLDING {
            self.dontRefresh = true
            let destination = segue.destination as! HoldingViewController
            destination.holding = self.holdings[self.holdingsTableView.indexPathForSelectedRow!.row]
            self.holdingsTableView.deselectRow(at: self.holdingsTableView.indexPathForSelectedRow!, animated: true)
        }
    }

}

// MARK: - SwitchWatchlistDelegate Extension

extension DashboardViewController: SwitchWatchlistDelegate {
    
    /// Switches the currently displayed watchlist
    func switchWatchlist(_ newCoreWatchlist: CoreWatchlist) {
        self.coreWatchlist = newCoreWatchlist
        self.refresh()
    }
    
}

// MARK: - TableView Methods Extension

extension DashboardViewController {
    
    /// Returns how many sections the TableView has
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: holdings in watchlist
        return 1
    }
    
    /// Returns the number of rows in any given section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Once cell for every holding
        return self.holdings.count
    }
    
    /// Creates the cells and contents of the TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: holdings in watchlist
        
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
        let holding = self.holdings[indexPath.row]
        
        // Ticker label
        holdingCell.textLabel?.text = holding.ticker
        holdingCell.textLabel?.font = CustomFont.setBodyFont()
        
        // Ticker's day's return label
        if let watchlistIsOwned = self.coreWatchlist?.owned {
            if watchlistIsOwned {
                if let dayReturnInDollars = holding.getDayReturnInDollars(), let dayReturnInPercentage = holding.getDayReturnInPercentage() {
                    holdingCell.detailTextLabel?.text = Algorithm.getReturnDescription(returnInDollars: dayReturnInDollars, returnInPercentage: dayReturnInPercentage)
                    holdingCell.detailTextLabel?.textColor = Algorithm.getReturnColour(dayReturnInDollars)
                }
                else {
                    holdingCell.detailTextLabel?.text = Constant.ERROR_LABEL
                }
            }
            else {
                // Watchlist is not owned
                
                if let dayReturnInPercentage = holding.getDayReturnInPercentage() {
                    holdingCell.detailTextLabel?.text = Algorithm.getReturnInPercentageDescription(dayReturnInPercentage)
                    holdingCell.detailTextLabel?.textColor = Algorithm.getReturnColour(dayReturnInPercentage)
                }
                else {
                    holdingCell.detailTextLabel?.text = Constant.ERROR_LABEL
                }
            }
        }
        holdingCell.detailTextLabel?.font = CustomFont.setBodyFont()
        
        return holdingCell
    }
    
    /// Returns whether a given section can be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Holdings can't be deleted from this page
        return false
    }
    
    /// Returns the height of each cell
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.CELL_HEIGHT
    }
    
}
