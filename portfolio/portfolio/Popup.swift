//
//  Popup.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit

class Popup: NSObject {
    
    // MARK: - Methods
    
    /// Creates and shows a title and text popup with a 'Dismiss' option
    static func displayPopup(title: String, message: String, viewController: UIViewController) {
        // Define alert
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        // Add interaction to alert
        alertController.addAction(
            UIAlertAction(
                title: "Dismiss",
                style: .default,
                handler: nil
            )
        )
        // Present alert
        viewController.present(
            alertController,
            animated: true,
            completion: nil
        )
    }
    
}

