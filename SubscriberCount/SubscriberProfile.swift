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
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(channelName, forKey: "channelName")
        aCoder.encode(image, forKey: "image")
        aCoder.encode(id, forKey: "id")
    }
    
    required init?(coder aDecoder: NSCoder) {
        image = aDecoder.decodeObject(forKey: "image") as! UIImage
        channelName = aDecoder.decodeObject(forKey: "channelName") as! String
        id = aDecoder.decodeObject(forKey: "id") as! String
    }
    
}
