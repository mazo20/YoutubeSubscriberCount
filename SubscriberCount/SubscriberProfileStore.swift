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
    
    let profilesArchiveURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("decks.archive")
    }()
    
    override init() {
        if let archivedDecks = NSKeyedUnarchiver.unarchiveObject(withFile: profilesArchiveURL.path) as? [SubscriberProfile] {
            store += archivedDecks
        }
    }
    
    func saveChanges() -> Bool {
        print("Saving profiles to \(profilesArchiveURL.path)")
        var names = [String]()
        var ids = [String]()
        var images = [Data]()
        var subs = [String]()
        var size = store.count
        if size > 3 { size = 3 }
        for i in 0..<size {
            let profile = store[i]
            names.append(profile.channelName)
            ids.append(profile.id)
            subs.append(profile.subscriberCount)
            let data = NSData(data: UIImagePNGRepresentation(profile.image)!) as Data
            images.append(data)
            let defaults = UserDefaults(suiteName: "group.subscriberProfiles")
            defaults?.setValue(names, forKey: "names")
            defaults?.setValue(ids, forKey: "ids")
            defaults?.setValue(images, forKey: "images")
            defaults?.setValue(subs, forKey: "subs")
            
        }
        return NSKeyedArchiver.archiveRootObject(store, toFile: profilesArchiveURL.path)
    }
}
