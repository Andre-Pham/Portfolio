//
//  CoreDataController.swift
//  portfolio
//
//  Created by Andre Pham on 2/5/21.
//

import UIKit
import CoreData

class CoreDataController: NSObject {
    
    // MARK: - Properties
    
    // FetchedResultsControllers
    var allCoreWatchlistsFetchedResultsController: NSFetchedResultsController<CoreWatchlist>?
    
    // Other properties
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var childManagedContext: NSManagedObjectContext
    
    // MARK: - Constructor
    
    override init() {
        // Define persistent container
        persistentContainer = NSPersistentContainer(name: "PortfolioDataModel")
        persistentContainer.loadPersistentStores() {
            (description, error) in if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        
        // Initiate Child Managed Context
        self.childManagedContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.childManagedContext.parent = self.persistentContainer.viewContext
        
        super.init()
    }
    
    /// Retrieves all CoreWatchlist entities stored within Core Data persistent memory
    func fetchAllCoreWatchlists() -> [CoreWatchlist] {
        if allCoreWatchlistsFetchedResultsController == nil {
            // Instantiate fetch request
            let request: NSFetchRequest<CoreWatchlist> = CoreWatchlist.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // Initialise Fetched Results Controller
            allCoreWatchlistsFetchedResultsController = NSFetchedResultsController<CoreWatchlist>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // Set this class to be the results delegate
            allCoreWatchlistsFetchedResultsController?.delegate = self
            
            // Perform fetch request
            do {
                try allCoreWatchlistsFetchedResultsController?.performFetch()
            }
            catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let coreWatchlists = allCoreWatchlistsFetchedResultsController?.fetchedObjects {
            return coreWatchlists
        }
        
        return [CoreWatchlist]() // Empty
    }
    
}

extension CoreDataController: DatabaseProtocol {
    
    /// Checks if there are changes to be saved inside of the view context and then saves, if necessary
    func saveChanges() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            }
            catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    /// Saves the child context, hence pushing the changes to the parent context
    func saveChildToParent() {
        do {
            // Saving child managed context pushes it to Core Data
            try self.childManagedContext.save()
        }
        catch {
            fatalError("Failed to save child managed context to Core Data with error: \(error)")
        }
    }
    
    /// Creates a new listener that either fetches all watchlists
    func addListener(listener: DatabaseListener) {
        // Adds the new database listener to the list of listeners
        listeners.addDelegate(listener)
        
        // Provides the listener with the initial immediate results depending on the type
        if listener.listenerType == .watchlist || listener.listenerType == .all {
            listener.onAnyWatchlistChange(change: .update, coreWatchlists: fetchAllCoreWatchlists())
        }
    }
    
    /// Removes a specific listener
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func addCoreWatchlist(name: String, owned: Bool) -> CoreWatchlist {
        // Create CoreWatchlist entity
        let coreWatchlist = NSEntityDescription.insertNewObject(forEntityName: "CoreWatchlist", into: persistentContainer.viewContext) as! CoreWatchlist
        
        // Assign attributes to CoreWatchlist entity
        coreWatchlist.name = name
        coreWatchlist.owned = owned
        coreWatchlist.isPortfolio = false
        
        // CoreWatchlist is returned in case it has to be used after its added to Core Data
        return coreWatchlist
    }
    
    func deleteCoreWatchlist(coreWatchlist: CoreWatchlist) {
        persistentContainer.viewContext.delete(coreWatchlist)
    }
    
    func addCoreHoldingToCoreWatchlist(ticker: String, currency: String, coreWatchlist: CoreWatchlist) -> CoreHolding {
        // Create CoreHolding entity
        let coreHolding = NSEntityDescription.insertNewObject(forEntityName: "CoreHolding", into: persistentContainer.viewContext) as! CoreHolding
        
        // Assign attributes to CoreHolding entity
        coreHolding.ticker = ticker
        coreHolding.currency = currency
        
        // Add to CoreWatchlist entity
        coreWatchlist.addToHoldings(coreHolding)
        
        // CoreHolding is returned in case it has to be used after its added to Core Data
        return coreHolding
    }
    
    func deleteCoreHoldingFromCoreWatchlist(coreHolding: CoreHolding, coreWatchlist: CoreWatchlist) {
        coreWatchlist.removeFromHoldings(coreHolding)
    }
    
    func addCorePurchaseToCoreHolding(shares: Double, date: Date, price: Double, coreHolding: CoreHolding) -> CorePurchase {
        // Create CorePurchase entity
        let corePurchase = NSEntityDescription.insertNewObject(forEntityName: "CorePurchase", into: persistentContainer.viewContext) as! CorePurchase
        
        // Assign attributes to CorePurchase entity
        corePurchase.shares = shares
        corePurchase.date = date
        corePurchase.price = price
        
        // Add to CoreHolding entity
        coreHolding.addToPurchases(corePurchase)
        
        // CorePurchase is returned in case it has to be used after its added to Core Data
        return corePurchase
    }
    
    func deleteCorePurchaseFromCoreHolding(corePurchase: CorePurchase, coreHolding: CoreHolding) {
        coreHolding.removeFromPurchases(corePurchase)
    }
    
    func editCoreWatchlist(coreWatchlist: CoreWatchlist, newName: String, newOwned: Bool) {
        coreWatchlist.name = newName
        coreWatchlist.owned = newOwned
    }
    
    func portfolioAssigned() -> Bool {
        for coreWatchlist in self.fetchAllCoreWatchlists() {
            if coreWatchlist.isPortfolio {
                return true
            }
        }
        
        return false
    }
    
}

extension CoreDataController: NSFetchedResultsControllerDelegate {
    
    /// Called whenever the FetchedResultsController detects a change to the result of its fetch
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allCoreWatchlistsFetchedResultsController {
            listeners.invoke() {
                listener in if listener.listenerType == .watchlist || listener.listenerType == .all {
                    listener.onAnyWatchlistChange(change: .update, coreWatchlists: fetchAllCoreWatchlists())
                }
            }
        }
    }
    
}
