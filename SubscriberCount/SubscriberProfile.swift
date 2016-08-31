//
//  SubscriberProfile.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 31.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

class SubscriberProfile: NSObject {
    
    var image: UIImage?
    var liveSubscriberCount: String!
    var channelName: String!
    var videosCount: String!
    var viewsCount: String!
    var stuckSubscriberCount: String?
    var id: String?
    
    init(image: UIImage?, liveSubscriberCount: String, channelName: String, videosCount: String, viewsCount: String, stuckSubscriberCount: String?, id: String?) {
        if let img = image {
            self.image = img
        }
        
        self.liveSubscriberCount = liveSubscriberCount
        self.channelName = channelName
        self.videosCount = videosCount
        self.viewsCount = viewsCount
        if let idString = id {
            self.id = idString
        }
        if let stuck = stuckSubscriberCount {
            self.stuckSubscriberCount = stuck
        } else {
            self.stuckSubscriberCount = liveSubscriberCount
        }
        
        super.init()
    }
    
    
}