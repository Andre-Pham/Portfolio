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
        
        let image = UIImage(systemName: "square.and.arrow.up")
        
        // SOURCE: https://stackoverflow.com/questions/34039475/programmatically-set-the-uitabbaritem-icon-for-every-linked-viewcontroller
        // AUTHOR: Pascal - https://stackoverflow.com/users/1912227/pascal
        let tabBarItems = tabBar.items! as [UITabBarItem]
        //tabBarItems[0].title = "Settings".localized
        //tabBarItems[0].image = UIImage.fontAwesomeIconWithName(FontAwesome.Gears, textColor: UIColor.blueColor(), size: CGSizeMake(30, 30))
        tabBarItems[0].image = image

        // Do any additional setup after loading the view.
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
