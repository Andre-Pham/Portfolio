//
//  DatabaseProtocol.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import Foundation

// Defines chat type of change has been done to the database
enum DatabaseChange {
    case add
    case remove
    case update
}

// Specifies the type of data each listener has to deal with
enum ListenerType {
    case watchlist
    case all
}

// Protocol for listeners for when the database changes
protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    func onAnyWatchlistChange(change: DatabaseChange, coreWatchlists: [CoreWatchlist])
}

// Protocol for all functions for interacting with the database
protocol DatabaseProtocol: AnyObject {
    func saveChanges()
    func saveChildToParent()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    func addCoreWatchlist(name: String, owned: Bool) -> CoreWatchlist
    func deleteCoreWatchlist(coreWatchlist: CoreWatchlist)
    
    func addCoreHoldingToCoreWatchlist(ticker: String, coreWatchlist: CoreWatchlist) -> CoreHolding
    func deleteCoreHoldingFromCoreWatchlist(coreHolding: CoreHolding, coreWatchlist: CoreWatchlist)
    
    func addCorePurchaseToCoreHolding(shares: Double, date: Date, price: Double, coreHolding: CoreHolding) -> CorePurchase
    func deleteCorePurchaseFromCoreHolding(corePurchase: CorePurchase, coreHolding: CoreHolding)
    
    func editCoreWatchlist(coreWatchlist: CoreWatchlist, newName: String, newOwned: Bool)
}
