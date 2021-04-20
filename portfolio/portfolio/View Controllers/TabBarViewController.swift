//
//  TabBarViewController.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SOURCE: https://stackoverflow.com/questions/34039475/programmatically-set-the-uitabbaritem-icon-for-every-linked-viewcontroller
        // AUTHOR: Pascal - https://stackoverflow.com/users/1912227/pascal
        let tabBarItems = tabBar.items! as [UITabBarItem]
        tabBarItems[0].image = UIImage(systemName: "sun.max")
        tabBarItems[0].selectedImage = UIImage(systemName: "sun.max.fill")
        tabBarItems[1].image = UIImage(systemName: "chart.pie")
        tabBarItems[1].selectedImage = UIImage(systemName: "chart.pie.fill")
        tabBarItems[2].image = UIImage(systemName: "chart.bar")
        tabBarItems[2].selectedImage = UIImage(systemName: "chart.bar.fill")
        tabBarItems[3].image = UIImage(systemName: "newspaper")
        tabBarItems[3].selectedImage = UIImage(systemName: "newspaper.fill")
        tabBarItems[4].image = UIImage(systemName: "bookmark")
        tabBarItems[4].selectedImage = UIImage(systemName: "bookmark.fill")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
