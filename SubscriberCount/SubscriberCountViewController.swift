//
//  SubscriberCountViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

//public var publicId = "UCtinbF-Q-fVthA0qrFQTgXQ"
public struct Public {
    static var id = "UC-lHJZR3Gqxm24_Vd_AJ5Yw"
}

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
    var repeatLabel: UILabel!
    var noIDLabel: UILabel!
    var timer: NSTimer!
    var repeatButton: UIButton!
    var name = ""
    
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
        
        var frame = CGRect(origin: CGPointZero, size: CGSize(width: 70, height: 70))
        loadingAnimation = NVActivityIndicatorView(frame: frame, type: .BallPulse, color: UIColor.blackColor(), padding: nil)
        loadingAnimation.center = self.view.center
        self.view.addSubview(loadingAnimation)
        loadingAnimation.hidesWhenStopped = true
        loadingAnimation.startAnimation()
        
        
        repeatButton = UIButton(frame: frame)
        repeatButton.addTarget(self, action: #selector(self.update), forControlEvents: .TouchUpInside)
        repeatButton.center = self.view.center
        repeatButton.center.y+=150
        repeatButton.setImage(UIImage(imageLiteral: "Synchronize.png"), forState: .Normal)
        self.view.addSubview(repeatButton)
        
        frame = CGRect(origin: CGPointZero, size: CGSize(width: 320, height: 100))
        repeatLabel = UILabel(frame: frame)
        repeatLabel.text = "Oops!\nSomething went wrong"
        repeatLabel.font = repeatLabel.font.fontWithSize(20)
        repeatLabel.numberOfLines = 3
        repeatLabel.center = self.view.center
        repeatLabel.center.y-=50
        repeatLabel.textAlignment = .Center
        self.view.addSubview(repeatLabel)
        noIDLabel = UILabel(frame: frame)
        noIDLabel.text = "No channel found!\nSearch for something else"
        noIDLabel.font = noIDLabel.font.fontWithSize(20)
        noIDLabel.numberOfLines = 3
        noIDLabel.center = self.view.center
        noIDLabel.textAlignment = .Center
        self.view.addSubview(noIDLabel)
        
        shouldShowError(false)
        
        searchTextField.layer.borderColor = UIColor.blackColor().CGColor
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.cornerRadius = 5
        
        visualEffect.frame = self.view.bounds
        visualEffect.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        imageView.contentMode = .ScaleAspectFill
        imageView.bounds = self.view.bounds
        imageView.center = self.view.center
        self.view.addSubview(imageView)
        self.view.addSubview(visualEffect)
        self.view.sendSubviewToBack(visualEffect)
        self.view.sendSubviewToBack(imageView)
        visualEffect.effect = UIBlurEffect(style: UIBlurEffectStyle.Light)
       
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = UIColor.blackColor().CGColor
        thumbnailImageView.clipsToBounds = true
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
        _ = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(self.updateStuckSubscriberCount), userInfo: nil, repeats: true)
        
        if store.store.count > 0 {
            let index = Int(arc4random_uniform(UInt32(store.store.count)))
            newProfile(withName: store.store[index].id)
        } else {
            newProfile(withName: Public.id)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        updateBookmark()
    }
    
    @IBAction func shareButton(sender: AnyObject) {
        let firstActivityItem = "To be added"
        
        let activityViewController = UIActivityViewController(activityItems: [firstActivityItem], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
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
        if self.repeatLabel.hidden {
            updateBookmark(true)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        name = textField.text!
        newProfile(withName: name)
        return false
    }
    
    func updateBookmark(changeState: Bool? = nil) {
        let profileInStore = self.store.store.filter{$0.id == Public.id}.first
        if let profileInStore = profileInStore {
            if let _ = changeState {
                let index = self.store.store.indexOf(profileInStore)
                self.store.store.removeAtIndex(index!)
                self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Empty.png")
            } else {
                self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Filled.png")
            }
            
        } else {
            if let _ = changeState {
                let subscriberProfile = SubscriberProfile(image: self.thumbnailImageView.image!, channelName: self.channelNameLabel.text!, id: Public.id)
                self.store.store.append(subscriberProfile)
                self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Filled.png")
            } else {
                self.bookmarkButton.image = UIImage(imageLiteral: "Bookmark_Empty.png")
            }
        }
    }
    
    func shouldShowError(isTrue: Bool, error: Error? = nil) {
        if isTrue {
            if let errorType = error {
                switch errorType {
                case .IDError:
                    self.noIDLabel.hidden = false
                default:
                    self.repeatLabel.hidden = false
                    self.repeatButton.hidden = false
                }
            }
        } else {
            self.repeatLabel.hidden = true
            self.repeatButton.hidden = true
            self.noIDLabel.hidden = true
        }
    }
    
    func update() {
        newProfile(withName: name)
        shouldShowError(false)
    }
    
    func newProfile(withName name: String) {
        shouldShowError(false)
        self.stackView.hidden = true
        loadingAnimation.startAnimation()
        timer.invalidate()
        YoutubeAPI.parseAllData(name, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateView(withValues: result as! [String: AnyObject])
                    self.updateBookmark()
                    self.stackView.hidden = false
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
                    self.loadingAnimation.stopAnimation()
                }
            case let .Failure(error):
                print(error)
                let errorType = error as! Error
                dispatch_async(dispatch_get_main_queue()) {
                    self.shouldShowError(true, error: errorType)
                    self.loadingAnimation.stopAnimation()
                }
            }
        })
    }
    
    func updateLiveSubscriberCount() {
        YoutubeAPI.parseData(forID: Public.id, parameters: [.Data], completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                self.updateView(withValues: result as! [String: AnyObject])
            case let .Failure(error):
                print(error)
            }
        })
    }
    
    func updateStuckSubscriberCount() {
        YoutubeAPI.parseData(forID: Public.id, parameters: [.StuckSubscriberCount], completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                self.updateView(withValues: result as! [String: AnyObject])
            case let .Failure(error):
                print(error)
            }
        })
    }
    
    func updateView(withValues values: [String: AnyObject]) {
        if let channel = values["channelName"] as? String  { self.channelNameLabel.text = channel }
        if let liveSubCount = values["liveSubscriberCount"] as? String { self.liveSubscriberCountLabel.text = liveSubCount }
        if let stuckSubCount = values["stuckSubscriberCount"] as? String { self.stuckSubscriberCountLabel.text = stuckSubCount }
        if let views = values["viewsCount"] as? String { self.viewsCountLabel.text = views }
        if let videos = values["videosCount"] as? String { self.videoCountLabel.text = videos }
        if let id = values["id"] as? String { Public.id = id }
        if let image = values["image"] as? UIImage {
            self.imageView.image = image
            self.thumbnailImageView.image = image
        }
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
        newProfile(withName: data)
    }
}
