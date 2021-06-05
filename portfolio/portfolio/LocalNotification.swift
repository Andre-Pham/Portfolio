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
    static let MARKET_STATUS_NOTIFICATION_IDENTIFIER = "marketStatusNotification"
    
    static func startMarketStatusNotifications() {
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
            var timeTrigger = DateComponents()
            timeTrigger.hour = 10
            timeTrigger.minute = 30
            timeTrigger.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: timeTrigger, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: MARKET_STATUS_NOTIFICATION_IDENTIFIER+String(day),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
    
}
