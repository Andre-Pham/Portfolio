//
//  NewWatchlistViewController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class NewWatchlistViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ownedSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController
        // from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    @IBAction func saveBarButtonPressed(_ sender: Any) {
        // TODO - ADD POPUP VALIDATION FOR NAME ENTERED
        let newWatchlist = databaseController?.addCoreWatchlist(name: nameTextField.text ?? "", owned: ownedSwitch.isOn)
        if let isPortfolioAssigned = databaseController?.portfolioAssigned(), let watchlistOwned = newWatchlist?.owned {
            if watchlistOwned {
                newWatchlist!.isPortfolio = !isPortfolioAssigned
            }
        }
        databaseController?.saveChanges()
        
        navigationController?.popViewController(animated: true)
        return
    }
    
}
