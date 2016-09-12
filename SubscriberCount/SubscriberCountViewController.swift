//
//  SubscriberCountViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import SubscriberCountKit
import CoreSpotlight
import MobileCoreServices

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
    var textFieldShouldBecomeFirstResponder = false
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        if activity.activityType == CSSearchableItemActionType {
            if let userInfo = activity.userInfo {
                let selectedProfile = userInfo[CSSearchableItemActivityIdentifier] as! String
                name = selectedProfile
                newProfile(withName: name)
                print(selectedProfile)
            }
        }
    }
    
    func searchTextFieldBecomeFirstResponder() {
        if let textField = searchTextField {
            textField.becomeFirstResponder()
        }
        textFieldShouldBecomeFirstResponder = true
    }
    
    override func viewDidLoad() {
        if textFieldShouldBecomeFirstResponder {
            searchTextField.becomeFirstResponder()
        }
        
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
        
        _ = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(self.updateStuckSubscriberCount), userInfo: nil, repeats: true)
        
        if store.store.count > 0 {
            newProfile(withName: store.store[0].id)
        } else {
            newProfile(withName: Public.id)
        }
        
    }
    
    @IBAction func tapGestureRecognizer(sender: AnyObject) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        updateBookmark()
    }
    
    @IBAction func shareButton(sender: AnyObject) {
        guard !self.stackView.hidden else { return }
        let firstActivityItem = "\(self.channelNameLabel.text!) subscriber count is \(self.liveSubscriberCountLabel.text!) - via SubTrack. Download at www.appstore.com"
        
        
        let window = UIApplication.sharedApplication().delegate!.window!!
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
        window.drawViewHierarchyInRect(window.bounds, afterScreenUpdates: true)
        let windowImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //now position the image x/y away from the top-left corner to get the portion we want
        var size = self.stackView.frame.size
        size.height+=40
        size.width+=20
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        windowImage.drawAtPoint(CGPoint(x: -self.stackView.frame.origin.x+10, y: -self.stackView.frame.origin.y+20))
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let secondActivityItem = image
        
        let activityViewController = UIActivityViewController(activityItems: [firstActivityItem, secondActivityItem], applicationActivities: nil)
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
        if let timer = timer {
            timer.invalidate()
        }
        YoutubeAPI.parseAllData(name, completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                dispatch_async(dispatch_get_main_queue()) {
                    let k = result as! [String: AnyObject]
                    self.updateView(withValues: result as! [String: AnyObject])
                    let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
                    searchableItemAttributeSet.title = (k["channelName"] as! String)
                    let data = NSData(data: UIImagePNGRepresentation(k["image"] as! UIImage)!)
                    searchableItemAttributeSet.thumbnailData = data
                    let keywords = k["channelName"] as! String
                    searchableItemAttributeSet.keywords =
                        keywords.componentsSeparatedByString(" ")
                    
                    let searchableItem = CSSearchableItem(uniqueIdentifier: (k["id"] as! String), domainIdentifier: "channels", attributeSet: searchableItemAttributeSet)
                    
                    CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([searchableItem], completionHandler: { (ErrorType) -> Void in
                        if (ErrorType != nil) {
                            print("indexing failed \(ErrorType)")
                        }
                    })
                    self.updateBookmark()
                    self.stackView.hidden = false
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
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
        name = data
        newProfile(withName: name)
        searchTextField.text = ""
    }
}
