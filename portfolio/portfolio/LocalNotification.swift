//
//  LocalNotification.swift
//  portfolio
//
//  Created by Andre Pham on 5/6/21.
//

import UIKit

class LocalNotification: NSObject {
    
    static let appDelegate = {
        return UIApplication.shared.delegate as! AppDelegate
    }()
    static let MARKET_OPEN_NOTIFICATION_IDENTIFIER = "marketOpenNotification"
    static let MARKET_CLOSE_NOTIFICATION_IDENTIIFER = "marketCloseNotification"
    
    static func startMarketStatusNotifications(time: DateComponents, identifier: String) {
        guard LocalNotification.appDelegate.notificationsEnabled else {
            return
        }
        
        let content = UNMutableNotificationContent()
        if identifier == MARKET_OPEN_NOTIFICATION_IDENTIFIER {
            content.title = "Markets Now Open!"
            content.body = "Tap to view your Dashboard for today."
        }
        else if identifier == MARKET_CLOSE_NOTIFICATION_IDENTIIFER {
            content.title = "Markets Have Closed"
            content.body = "Tap to see your portfolio's and watchlists' performance for today."
        }
        else {
            fatalError("startMarketStatusNotifications used incorrectly, identifier was not set to one of two options")
        }
        content.badge = NSNumber(value: 1)
        
        // 1: Sunday, 2: Monday, etc.
        for day in 2...6 {
            // Notification triggers every weekday at 10:30 am
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
