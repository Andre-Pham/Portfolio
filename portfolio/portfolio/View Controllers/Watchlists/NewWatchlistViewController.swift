//
//  NewWatchlistViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class NewWatchlistViewController: UIViewController {
    
    // MARK: - Properties
    
    // Core Data
    weak var databaseController: DatabaseProtocol?

    // MARK: - Outlets
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ownedSwitch: UISwitch!
    
    // MARK: - Methods
    
    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    // MARK: - Actions
    
    /// Saves the new watchlist if save button is pressed
    @IBAction func saveBarButtonPressed(_ sender: Any) {
        
        let watchlistName = self.nameTextField.text
        let trimmedWatchlistName = watchlistName?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation
        if trimmedWatchlistName == "" {
            Popup.displayPopup(title: "No Name Provided", message: "You must enter a name with at least one character.", viewController: self)
            return
        }
        
        // Create and add new watchlist to database
        let newWatchlist = databaseController?.addCoreWatchlist(name: watchlistName ?? "", owned: self.ownedSwitch.isOn)
        if let isPortfolioAssigned = databaseController?.portfolioAssigned(), let watchlistOwned = newWatchlist?.owned {
            if watchlistOwned {
                newWatchlist!.isPortfolio = !isPortfolioAssigned
            }
        }
        databaseController?.saveChanges()
        
        navigationController?.popViewController(animated: true)
    }
    
}
