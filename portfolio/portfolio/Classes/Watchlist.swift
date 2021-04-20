//
//  Watchlist.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class Watchlist: NSObject {
    
    // MARK: - Properties
    
    var name: String?
    var holdings: [Holding]? = []
    var owned: Bool?
    
    init(name: String, owned: Bool) {
        self.name = name
        self.owned = owned
    }
    
    /*
     if let _ = self.owned, self.owned == true {
         return self.currentPrice! * self.sharesOwned!
     }
     */

}
