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

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    // Constants
    let CELL_HOLDING = "holdingCell"
    let KEYPATH_TABLEVIEW_HEIGHT = "tableViewHeightKeyPath"
    
    // Other properties
    var shownWatchlist: Watchlist?
    
    // MARK: - Outlets
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var dateAndReturnsStackView: UIStackView!
    @IBOutlet weak var rootStackView: UIStackView!
    @IBOutlet weak var holdingsTableViewHeight: NSLayoutConstraint!
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TESTING
        let holding1 = Holding(ticker: "TEST", dates: ["TEST_DATE"], prices: [100], currentPrice: 100)
        let holding2 = Holding(ticker: "TEST2", dates: ["TEST_DATE2"], prices: [200], currentPrice: 200)
        
        self.shownWatchlist = Watchlist(name: "TEST_NAME", owned: false)
        self.shownWatchlist?.holdings?.append(holding1)
        self.shownWatchlist?.holdings?.append(holding2)
        self.shownWatchlist?.holdings?.append(holding2)
        self.shownWatchlist?.holdings?.append(holding2)
        self.shownWatchlist?.holdings?.append(holding2)
        self.shownWatchlist?.holdings?.append(holding2)
        self.shownWatchlist?.holdings?.append(holding2)
        
        //rootStackView.addBackground(color: .red)
        // TESTING END

        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        // Add the line chart to the view
        self.addChartView()
        
        // Add margins to the stack views
        rootStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 10)
        rootStackView.isLayoutMarginsRelativeArrangement = true
        dateAndReturnsStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 20)
        dateAndReturnsStackView.isLayoutMarginsRelativeArrangement = true
    }
    
    /// Calls before the view appears on screen
    override func viewWillAppear(_ animated: Bool) {
        // Adds an observer which calls observeValue when number of cells changes
        self.holdingsTableView.addObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT, options: .new, context: nil)
        self.holdingsTableView.reloadData()
    }
    
    /// Calls before the view disappears on screen
    override func viewWillDisappear(_ animated: Bool) {
        // Remove observer which calls observeValue when number of cells changes
        self.holdingsTableView.removeObserver(self, forKeyPath: KEYPATH_TABLEVIEW_HEIGHT)
    }
    
    /// Calls when triggered by an observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // SOURCE: https://www.youtube.com/watch?v=INkeINPZddo
        // AUTHOR: Divyesh Gondaliya - https://www.youtube.com/channel/UC4pRJw6rNrHuFZV3aOELJkA
        if keyPath == KEYPATH_TABLEVIEW_HEIGHT {
            // Changes TableView height based on number of cells so they're not squished into a nested scroll view
            if let newValue = change?[.newKey] {
                let newSize = newValue as! CGSize
                self.holdingsTableViewHeight.constant = newSize.width
            }
        }
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
        return self.shownWatchlist?.holdings?.count ?? 0
    }
    
    /// Creates the cells and contents of the TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section: holdings in watchlist
        
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
        let holding = self.shownWatchlist?.holdings?[indexPath.row]
        
        holdingCell.textLabel?.text = holding?.ticker
        holdingCell.detailTextLabel?.text = holding?.ticker
        
        return holdingCell
    }
    
    /// Returns whether a given section can be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Holdings can be deleted
        return true
    }
    
}

// MARK: - SwiftUI Chart Methods Extension

extension DashboardViewController {
    
    /// Creates then adds a SwiftUI chart to the current view
    func addChartView() {
        let swiftUIView = ChartView()
        
        let chartData = ChartData(title: "Title", legend: "Legend", data: [100,23,54,32,12,37,7,23,43,-5])
        addSubSwiftUIView(swiftUIView, to: view, chartData: chartData)
        
        // TESTING
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            chartData.data = [5, 10, 100.0]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            chartData.data = [5, 10, 10000.0]
        }
        // TESTING END
    }

    /// Adds the SwiftUI chart view as a child to DashboardViewController
    func addSubSwiftUIView<Content>(_ swiftUIView: Content, to view: UIView, chartData: ChartData) where Content : View {
        // SOURCE: https://www.avanderlee.com/swiftui/integrating-swiftui-with-uikit/
        // AUTHOR: ANTOINE VAN DER LEE - https://www.avanderlee.com/
        
        // Create SwiftUI view (chartViewHostingController) and add it as a child to DashboardViewController
        let chartViewHostingController = UIHostingController(rootView: swiftUIView.environmentObject(chartData))
        addChild(chartViewHostingController)

        // Insert the SwiftUI view without overlap
        rootStackView.insertArrangedSubview(chartViewHostingController.view, at: 0)

        // Add constraints to the SwiftUI view
        chartViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            chartViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chartViewHostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        ]
        NSLayoutConstraint.activate(constraints)

        // Notify the SwiftUI view that it has been moved to DashboardViewController
        chartViewHostingController.didMove(toParent: self)
    }
    
}

// TESTING
/*
extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}
*/
// TESTING END
