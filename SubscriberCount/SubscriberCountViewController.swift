//
//  SubscriberCountViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

public var publicId = "UCtinbF-Q-fVthA0qrFQTgXQ"

class SubscriberCountViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var channelNameLabel: UILabel!
    @IBOutlet var liveSubscriberCountLabel: UILabel!
    @IBOutlet var stuckSubscriberCountLabel: UILabel!
    @IBOutlet var videoCountLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var searchTextField: UITextField!
    
    let imageView = UIImageView()
    let visualEffect = UIVisualEffectView()
    
    override func viewDidLoad() {
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.translucent = true
        
        searchTextField.delegate = self
        searchTextField.returnKeyType = .Search
        searchTextField.autocorrectionType = .No
        searchTextField.clearButtonMode = .WhileEditing
        searchTextField.clearsOnBeginEditing = true
        
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
        
        self.thumbnailImageView.layer.cornerRadius = 10
        newProfile("caseyneistat")
        _ = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateView), userInfo: nil, repeats: true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        newProfile(textField.text!)
        return false
    }
    func newProfile(name: String) {
        YoutubeAPI.fetchAllData(name, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                dispatch_async(dispatch_get_main_queue()) {
                    let profile = result as! SubscriberProfile
                    if let image = profile.image {
                        self.imageView.image = image
                        self.thumbnailImageView.image = image
                    }
                    self.channelNameLabel.text = profile.channelName
                    self.liveSubscriberCountLabel.text = profile.liveSubscriberCount
                    self.viewsCountLabel.text = profile.viewsCount
                    self.videoCountLabel.text = profile.videosCount
                    self.stuckSubscriberCountLabel.text = profile.stuckSubscriberCount
                }
            case let .Failure(error):
                print(error)
            }
        })
    }
    func updateView() {
        YoutubeAPI.fetchSomeData(publicId, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                dispatch_async(dispatch_get_main_queue()) {
                    let profile = result as! SubscriberProfile
                    self.channelNameLabel.text = profile.channelName
                    self.liveSubscriberCountLabel.text = profile.liveSubscriberCount
                    self.viewsCountLabel.text = profile.viewsCount
                    self.videoCountLabel.text = profile.videosCount
                }
            case let .Failure(error):
                print(error)
            }
        })
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
