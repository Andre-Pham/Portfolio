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
    @IBOutlet weak var disclaimerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Labels
        self.titleLabel.font = CustomFont.setLargeFont()
        self.contextLabel.font = CustomFont.setBodyFont()
        self.marketOpenDescriptionLabel.font = CustomFont.setBodyFont()
        self.marketCloseDescriptionLabel.font = CustomFont.setBodyFont()
        self.disclaimerLabel.font = CustomFont.setDetailFont()
        
        // Button
        saveButton.backgroundColor = UIColor(named: "GreyBlack1")
        saveButton.layer.cornerRadius = 5
        saveButton.titleLabel?.font = CustomFont.setButtonFont()
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        // Make sure previous notifications are cleared
        for day in 2...6 {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers:[LocalNotification.MARKET_OPEN_NOTIFICATION_IDENTIFIER+String(day),
                     LocalNotification.MARKET_CLOSE_NOTIFICATION_IDENTIIFER+String(day)]
            )
        }
        
        // Add new notifications
        let dates = [self.marketOpenDatePicker.date, self.marketCloseDatePicker.date]
        for (index, date) in dates.enumerated() {
            // Retreive times
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            // Form time for market open/close via DateComponents
            var time = DateComponents()
            time.hour = components.hour!
            time.minute = components.minute!
            // Get identifier
            var identifier: String
            if index == 0 {
                identifier = LocalNotification.MARKET_OPEN_NOTIFICATION_IDENTIFIER
            }
            else {
                identifier = LocalNotification.MARKET_CLOSE_NOTIFICATION_IDENTIIFER
            }
            // Start notificatinos for market open/close
            LocalNotification.startMarketStatusNotifications(time: time, identifier: identifier)
        }
        
        dismiss(animated: true, completion: nil)
    }

}
