//
//  TabBarViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    // MARK: - Properties
    
    let TABBAR_ICONS = ["sun.max", "chart.pie", "chart.bar", "newspaper", "bookmark"]
    
    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SOURCE: https://stackoverflow.com/questions/34039475/programmatically-set-the-uitabbaritem-icon-for-every-linked-viewcontroller
        // AUTHOR: Pascal - https://stackoverflow.com/users/1912227/pascal
        // Change the icons for the different tab bar items
        let tabBarItems = tabBar.items! as [UITabBarItem]
        for tabBarItemIndex in 0...4 {
            tabBarItems[tabBarItemIndex].image = UIImage(systemName: self.TABBAR_ICONS[tabBarItemIndex])
            tabBarItems[tabBarItemIndex].selectedImage = UIImage(systemName: self.TABBAR_ICONS[tabBarItemIndex] + ".fill")
        }
    }

}
