//
//  SubscriberCountViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

public var publicId = "UCtinbF-Q-fVthA0qrFQTgXQ"

class SubscriberCountViewController: UIViewController, UITextFieldDelegate, SendIdDelegate {
    
    var store: SubscriberProfileStore!
    
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var channelNameLabel: UILabel!
    @IBOutlet var liveSubscriberCountLabel: UILabel!
    @IBOutlet var stuckSubscriberCountLabel: UILabel!
    @IBOutlet var videoCountLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var bookmarkButton: UIBarButtonItem!
    @IBOutlet var stackView: UIStackView!
    
    let imageView = UIImageView()
    let visualEffect = UIVisualEffectView()
    var loadingAnimation: NVActivityIndicatorView!
    var label: UILabel!
    var timer: NSTimer!
    
    
    override func viewDidLoad() {
        stackView.hidden = true
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.blackColor()
        
        searchTextField.delegate = self
        searchTextField.returnKeyType = .Search
        searchTextField.autocorrectionType = .No
        searchTextField.clearButtonMode = .WhileEditing
        searchTextField.clearsOnBeginEditing = true
        
        let frame = CGRect(origin: CGPointZero, size: CGSize(width: 70, height: 70))
        loadingAnimation = NVActivityIndicatorView(frame: frame, type: .BallPulse, color: UIColor.blackColor(), padding: nil)
        loadingAnimation.center = self.view.center
        self.view.addSubview(loadingAnimation)
        loadingAnimation.hidesWhenStopped = true
        loadingAnimation.startAnimation()
        
        label = UILabel(frame: frame)
        label.text = "Problem with internet conneciton"
        label.center = self.view.center
        self.view.addSubview(label)
        label.hidden = true
        
        
        visualEffect.frame = self.view.bounds
        visualEffect.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        imageView.contentMode = .ScaleAspectFill
        imageView.bounds = self.view.bounds
        imageView.center = self.view.center
        self.view.addSubview(imageView)
        self.view.addSubview(visualEffect)
        self.view.sendSubviewToBack(visualEffect)
        self.view.sendSubviewToBack(imageView)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        visualEffect.effect = blurEffect
        
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.clipsToBounds = true
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
        _ = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(self.updateStuckSubscriberCount), userInfo: nil, repeats: true)
        if store.store.count > 0 {
            let index = random()%store.store.count
            newProfile(store.store[index].id)
        } else {
            newProfile(publicId)
        }
        
    }
    override func viewWillAppear(animated: Bool) {
        var hasProfile = false
        for profile in self.store.store {
            if profile.id == publicId {
                hasProfile = true
                break
            }
        }
        if !hasProfile {
            self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Empty.png")
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        newProfile(textField.text!)
        return false
    }
    @IBAction func shareButton(sender: AnyObject) {
        let firstActivityItem = NSURL(string: "https://itunes.apple.com/bh/app/facebook/id284882215?mt=8")!
        
        let activityViewController = UIActivityViewController(activityItems: [firstActivityItem], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivityTypePostToWeibo,
            UIActivityTypeMail,
            UIActivityTypeAirDrop,
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo,
            UIActivityTypePostToTencentWeibo
        ]
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    @IBAction func saveProfile(sender: AnyObject) {
        var hasProfile = false
        for profile in self.store.store {
            if profile.id == publicId {
                hasProfile = true
                let index = store.store.indexOf(profile)
                store.store.removeAtIndex(index!)
                self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Empty.png")
                break
            }
        }
        if !hasProfile {
            let subscriberProfile = SubscriberProfile(image: self.thumbnailImageView.image!, channelName: self.channelNameLabel.text!, id: publicId)
            self.store.store.append(subscriberProfile)
            self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Filled.png")
        }
        
    }
    
    func newProfile(name: String) {
        self.stackView.hidden = true
        loadingAnimation.startAnimation()
        timer.invalidate()
        YoutubeAPI.fetchAllData(name, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                dispatch_async(dispatch_get_main_queue()) {
                    let subscriberDictionary = result as! [String: AnyObject]
                    if let channel = subscriberDictionary["channelName"] as? String, liveSubCount = subscriberDictionary["liveSubscriberCount"] as? String, views = subscriberDictionary["viewsCount"] as? String, videos = subscriberDictionary["videosCount"] as? String, image = subscriberDictionary["image"] as? UIImage, stuckSubCount = subscriberDictionary["stuckSubscriberCount"] as? String {
                        self.imageView.image = image
                        self.thumbnailImageView.image = image
                        self.channelNameLabel.text = channel
                        self.liveSubscriberCountLabel.text = liveSubCount
                        self.viewsCountLabel.text = views
                        self.videoCountLabel.text = videos
                        self.stuckSubscriberCountLabel.text = stuckSubCount
                        
                        publicId = subscriberDictionary["id"] as! String
                        
                        var hasProfile = false
                        for profile in self.store.store {
                            if profile.id == publicId {
                                hasProfile = true
                                break
                            }
                        }
                        if hasProfile {
                            self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Filled.png")
                        } else {
                            self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Empty.png")
                        }
                        
                        self.stackView.hidden = false
                        self.loadingAnimation.stopAnimation()
                        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
                    } else {
                        self.stackView.hidden = false
                        self.loadingAnimation.stopAnimation()
                        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
                    }
                }
            case let .Failure(error):
                print(error)
                dispatch_async(dispatch_get_main_queue()) {
                    self.stackView.hidden = false
                    self.loadingAnimation.stopAnimation()
                    //self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
                }
            }
        })
    }
    
    func updateLiveSubscriberCount() {
        YoutubeAPI.fetchSomeData(publicId, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                dispatch_async(dispatch_get_main_queue()) {
                    let subscriberDictionary = result as! [String: AnyObject]
                    if let channel = subscriberDictionary["channelName"] as? String, liveSubCount = subscriberDictionary["liveSubscriberCount"] as? String, views = subscriberDictionary["viewsCount"] as? String, videos = subscriberDictionary["videosCount"] as? String {
                        self.channelNameLabel.text = channel
                        self.liveSubscriberCountLabel.text = liveSubCount
                        self.viewsCountLabel.text = views
                        self.videoCountLabel.text = videos
                    }
                }
            case let .Failure(error):
                print(error)
            }
        })
    }
    
    func updateStuckSubscriberCount() {
        YoutubeAPI.fetchStuckSubscriberCount(publicId, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                self.stuckSubscriberCountLabel.text = (result as! String)
            case let .Failure(error):
                print(error)
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Bookmarks" {
            let navController = segue.destinationViewController as! UINavigationController
            let bookmarksViewController = navController.topViewController as! BookmarksTableViewController
            bookmarksViewController.store = self.store
            bookmarksViewController.delegate = self
            
        }
    }
    
    func sendData(data: String) {
        newProfile(data)
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
