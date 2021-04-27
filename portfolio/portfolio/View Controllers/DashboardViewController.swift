//
//  DashboardViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit
import SwiftUI

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    @IBOutlet weak var mStackView: UIStackView!
    var shownWatchlist: Watchlist?
    let CELL_HOLDING = "holdingCell"
    
    @IBOutlet weak var holdingsTableView: UITableView!
    @IBOutlet weak var DashboardStatsStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TESTING
        let holding1 = Holding(ticker: "TEST", dates: ["TEST_DATE"], prices: [100], currentPrice: 100)
        let holding2 = Holding(ticker: "TEST2", dates: ["TEST_DATE2"], prices: [200], currentPrice: 200)
        
        self.shownWatchlist = Watchlist(name: "TEST_NAME", owned: false)
        self.shownWatchlist?.holdings?.append(holding1)
        self.shownWatchlist?.holdings?.append(holding2)
        // TESTING END

        // SOURCE: https://stackoverflow.com/questions/33234180/uitableview-example-for-swift
        // AUTHOR: Suragch - https://stackoverflow.com/users/3681880/suragch
        self.holdingsTableView.delegate = self
        self.holdingsTableView.dataSource = self
        
        self.addSwiftUIView()
        
        // MARGINS FOR STACK VIEW
        mStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 10)
        mStackView.isLayoutMarginsRelativeArrangement = true
        DashboardStatsStackView.directionalLayoutMargins = .init(top: 10, leading: 20, bottom: 20, trailing: 20)
        DashboardStatsStackView.isLayoutMarginsRelativeArrangement = true
        
        
        
        // Add dynamic height - SEARCH UP HOW
        NSLayoutConstraint.activate([
            holdingsTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // TESTING
        //mStackView.addBackground(color: .red)
    }
    
    func addSwiftUIView() {
        let swiftUIView = ChartSwiftUIView()
        addSubSwiftUIView(swiftUIView, to: view)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownWatchlist?.holdings?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Only one section
        let holdingCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLDING, for: indexPath)
        let holding = self.shownWatchlist?.holdings?[indexPath.row]
        
        holdingCell.textLabel?.text = holding?.ticker
        holdingCell.detailTextLabel?.text = holding?.ticker
        
        return holdingCell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}

// https://www.avanderlee.com/swiftui/integrating-swiftui-with-uikit/
extension DashboardViewController {

    func addSubSwiftUIView<Content>(_ swiftUIView: Content, to view: UIView) where Content : View {
        let chartObject = ChartObject(title: "Title", legend: "Legend", data: [100,23,54,32,12,37,7,23,43,-5])
        
        let hostingController = UIHostingController(rootView: swiftUIView.environmentObject(chartObject))

        /// Add as a child of the current view controller.
        addChild(hostingController)

        /// Add the SwiftUI view to the view controller view hierarchy.
//        view.addSubview(hostingController.view)
        mStackView.insertArrangedSubview(hostingController.view, at: 0)

        /// Setup the contraints to update the SwiftUI view boundaries.
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            //hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        ]
        //hostingController.view.widthAnchor.constraint(equalTo: view.widthAnchor),

        NSLayoutConstraint.activate(constraints)

        /// Notify the hosting controller that it has been moved to the current view controller.
        hostingController.didMove(toParent: self)
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
