//
//  LocalNotification.swift
//  portfolio
//
//  Created by Andre Pham on 5/6/21.
//

import UIKit

class LocalNotification: NSObject {
    
    // MARK: - Properties
    
    static let appDelegate = {
        return UIApplication.shared.delegate as! AppDelegate
    }()
    
    // Identifiers
    static let MARKET_OPEN_NOTIFICATION_IDENTIFIER = "marketOpenNotification"
    static let MARKET_CLOSE_NOTIFICATION_IDENTIIFER = "marketCloseNotification"
    
    // MARK: - Methods
    
    /// Assigns repeating local notifications that trigger every time the user's assigned market opens and closes
    static func startMarketStatusNotifications(time: DateComponents, identifier: String) {
        // Make sure notifications are enabled
        guard LocalNotification.appDelegate.notificationsEnabled else {
            return
        }
        
        // Set the content of the local notification
        let content = UNMutableNotificationContent()
        if identifier == MARKET_OPEN_NOTIFICATION_IDENTIFIER {
            content.title = "Markets Now Open!"
            content.body = "View your Dashboard to see today's changes."
        }
        else if identifier == MARKET_CLOSE_NOTIFICATION_IDENTIIFER {
            content.title = "Markets Have Closed"
            content.body = "View your Dashboard to see today's performance."
        }
        else {
            fatalError("startMarketStatusNotifications used incorrectly, identifier was not set to one of two options")
        }
        content.badge = NSNumber(value: 1)
        
        // 1: Sunday, 2: Monday, etc.
        for day in 2...6 {
            // Notification triggers Mon-Fri at the set time
            var triggerTime = time
            triggerTime.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerTime, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: identifier+String(day),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
    
}
