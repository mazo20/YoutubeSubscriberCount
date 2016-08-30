//
//  SubscriberCountViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

class SubscriberCountViewController: UIViewController {
    
    override func viewDidLoad() {
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.translucent = true
        
        let imageView = UIImageView()
        let visualEffect = UIVisualEffectView()
        visualEffect.frame = self.view.bounds
        visualEffect.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        imageView.contentMode = .ScaleAspectFill
        imageView.bounds = self.view.bounds
        imageView.center = self.view.center
        self.view.addSubview(imageView)
        self.view.addSubview(visualEffect)
        self.view.sendSubviewToBack(visualEffect)
        self.view.sendSubviewToBack(imageView)
        imageView.image = UIImage(imageLiteral: "Icon.png")
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        visualEffect.effect = blurEffect
        
        let youtube = YoutubeAPI.youtubeURL(method: .Channels, part: ["statistics", "snippet"], parameters: ["id": "UCtinbF-Q-fVthA0qrFQTgXQ"])
        let youtube1 = YoutubeAPI.youtubeURL(method: .Search, part: ["snippet"], parameters: ["q": "mazu 20", "type": "channel"])
        
        print(YoutubeAPI.idForName("caseyneistat"))
    }
    
    
    
}

class SubscriberNavigationController: UINavigationController {
    
    var statusBarStyle: UIStatusBarStyle = .Default {
        didSet {
            preferredStatusBarStyle()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }
}
