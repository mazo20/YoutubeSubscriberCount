//
//  SubscriberProfile.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 31.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

class SubscriberProfile: NSObject, NSCoding {
    
    var image: UIImage!
    var channelName: String!
    var id: String!
    
    init(image: UIImage, channelName: String, id: String) {
        self.image = image
        self.channelName = channelName
        self.id = id
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(channelName, forKey: "channelName")
        aCoder.encodeObject(image, forKey: "image")
        aCoder.encodeObject(id, forKey: "id")
    }
    required init?(coder aDecoder: NSCoder) {
        image = aDecoder.decodeObjectForKey("image") as! UIImage
        channelName = aDecoder.decodeObjectForKey("channelName") as! String
        id = aDecoder.decodeObjectForKey("id") as! String
    }
    
}