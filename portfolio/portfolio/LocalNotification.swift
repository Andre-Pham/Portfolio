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
            print("Notifications disabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Something has happened"
        content.body = "Tap to find out what..."
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
