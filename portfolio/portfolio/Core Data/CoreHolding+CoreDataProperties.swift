//
//  CoreHolding+CoreDataProperties.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//
//

import Foundation
import CoreData


extension CoreHolding {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreHolding> {
        return NSFetchRequest<CoreHolding>(entityName: "CoreHolding")
    }

    @NSManaged public var ticker: String?
    @NSManaged public var watchlist: CoreWatchlist?
    @NSManaged public var purchases: NSSet?

}

// MARK: Generated accessors for purchases
extension CoreHolding {

    @objc(addPurchasesObject:)
    @NSManaged public func addToPurchases(_ value: CorePurchase)

    @objc(removePurchasesObject:)
    @NSManaged public func removeFromPurchases(_ value: CorePurchase)

    @objc(addPurchases:)
    @NSManaged public func addToPurchases(_ values: NSSet)

    @objc(removePurchases:)
    @NSManaged public func removeFromPurchases(_ values: NSSet)

}

extension CoreHolding : Identifiable {

}
