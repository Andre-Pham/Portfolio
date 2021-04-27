//
//  Purchase.swift
//  portfolio
//
//  Created by Andre Pham on 21/4/21.
//

import UIKit

class Purchase: NSObject {
    
    // MARK: - Properties
    
    var date: String?
    var price: Double?
    var shares: Double?
    
    // MARK: - Constructor
    
    init(date: String, price: Double, shares: Double) {
        self.date = date
        self.price = price
        self.shares = shares
    }

}
