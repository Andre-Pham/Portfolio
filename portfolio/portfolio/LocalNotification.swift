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
    static let NOTIFICATION_IDENTIFIER = "marketStatusNotification"
    
    static func sendMarketStatusNotification() {
        guard LocalNotification.appDelegate.notificationsEnabled else {
            print("Notifications disabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Something has happened"
        content.body = "Tap to find out what..."
        content.badge = NSNumber(value: 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        let request = UNNotificationRequest(identifier: NOTIFICATION_IDENTIFIER, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
}
