//
//  CoreWatchlist+CoreDataProperties.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//
//

import Foundation
import CoreData


extension CoreWatchlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreWatchlist> {
        return NSFetchRequest<CoreWatchlist>(entityName: "CoreWatchlist")
    }

    @NSManaged public var name: String?
    @NSManaged public var owned: Bool
    @NSManaged public var holdings: NSSet?

}

// MARK: Generated accessors for holdings
extension CoreWatchlist {

    @objc(addHoldingsObject:)
    @NSManaged public func addToHoldings(_ value: CoreHolding)

    @objc(removeHoldingsObject:)
    @NSManaged public func removeFromHoldings(_ value: CoreHolding)

    @objc(addHoldings:)
    @NSManaged public func addToHoldings(_ values: NSSet)

    @objc(removeHoldings:)
    @NSManaged public func removeFromHoldings(_ values: NSSet)

}

extension CoreWatchlist : Identifiable {

}
