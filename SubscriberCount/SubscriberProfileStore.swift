//
//  SubscriberProfileStore.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 01.09.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

class SubscriberProfileStore: NSObject {
    var store = [SubscriberProfile]()
    let profilesArchiveURL: NSURL = {
        let documentsDirectories = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.URLByAppendingPathComponent("decks.archive")
    }()
    
    override init() {
        if let archivedDecks = NSKeyedUnarchiver.unarchiveObjectWithFile(profilesArchiveURL.path!) as? [SubscriberProfile] {
            store += archivedDecks
        }
    }
    
    func saveChanges() -> Bool {
        print("Saving profiles to \(profilesArchiveURL.path!)")
        return NSKeyedArchiver.archiveRootObject(store, toFile: profilesArchiveURL.path!)
    }
}
