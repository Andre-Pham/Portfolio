//
//  NotificationSettingsViewController.swift
//  portfolio
//
//  Created by Andre Pham on 6/6/21.
//

import UIKit

class SetNotificationSettingsViewController: UIViewController {
    
    @IBOutlet weak var marketOpenDatePicker: UIDatePicker!
    @IBOutlet weak var marketCloseDatePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIButton!
    
    // Labels
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contextLabel: UILabel!
    @IBOutlet weak var marketOpenDescriptionLabel: UILabel!
    @IBOutlet weak var marketCloseDescriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Labels
        self.titleLabel.font = CustomFont.setLargeFont()
        self.contextLabel.font = CustomFont.setBodyFont()
        self.marketOpenDescriptionLabel.font = CustomFont.setBodyFont()
        self.marketCloseDescriptionLabel.font = CustomFont.setBodyFont()
        
        // Button
        saveButton.backgroundColor = UIColor(named: "GreyBlack1")
        saveButton.layer.cornerRadius = 5
        saveButton.titleLabel?.font = CustomFont.setButtonFont()
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
    }

}
