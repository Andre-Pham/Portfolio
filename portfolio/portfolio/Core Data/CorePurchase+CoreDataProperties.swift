//
//  CorePurchase+CoreDataProperties.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//
//

import Foundation
import CoreData


extension CorePurchase {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CorePurchase> {
        return NSFetchRequest<CorePurchase>(entityName: "CorePurchase")
    }

    @NSManaged public var shares: Double
    @NSManaged public var date: Date?
    @NSManaged public var price: Double
    @NSManaged public var holding: CoreHolding?

}

extension CorePurchase : Identifiable {

}
