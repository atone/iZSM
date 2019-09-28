//
//  CoreDataHelper.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/27.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import Foundation
import CoreData

class CoreDataHelper {
    static let shared = CoreDataHelper()
    private init() {
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "iZSM")
        
        // Create a store description for a local store
        let localStoreLocation = NSPersistentCloudKitContainer.defaultDirectoryURL().appendingPathComponent("local.sqlite")
        let localStoreDescription = NSPersistentStoreDescription(url: localStoreLocation)
        localStoreDescription.configuration = "Local"
        
        // Create a store descpription for a CloudKit-backed local store
        let cloudStoreLocation = NSPersistentCloudKitContainer.defaultDirectoryURL().appendingPathComponent("cloud.sqlite")
        let cloudStoreDescription = NSPersistentStoreDescription(url: cloudStoreLocation)
        cloudStoreDescription.configuration = "Cloud"
        
        // Set the container options on the cloud store
        cloudStoreDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.cn.yunaitong.zsmth.cloudkit")
        
        // Update the container's list of store descriptions
        container.persistentStoreDescriptions = [localStoreDescription, cloudStoreDescription]
        
        // Load both stores
        container.loadPersistentStores() { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                dPrint("ERROR: Unresolved error \(error), \(error.userInfo)")
            }
        }
//        do {
//            try container.initializeCloudKitSchema(options: [])
//        } catch {
//            dPrint("ERROR: Unable to initialize CloudKit schema: \(error.localizedDescription)")
//        }
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                dPrint("ERROR: Unable to save context: \(error.localizedDescription)")
            }
        }
    }
}
