//
//  SubscriberCountViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import CoreSpotlight
import MobileCoreServices

public struct Public {
    static var id = "UC-lHJZR3Gqxm24_Vd_AJ5Yw"
}

class SubscriberCountViewController: UIViewController{
    
    var store: SubscriberProfileStore!
    var showNewProfile = true
    var idStore: [String: String] {
        if let store = UserDefaults.standard.object(forKey: "idStore") as? [String: String] {
            return store
        } else {
            return [String: String]()
        }
    }
    
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var channelNameLabel: UILabel!
    @IBOutlet var liveSubscriberCountLabel: UILabel!
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
    var timer: Timer?
    var repeatButton: UIButton!
    var name = ""
    var peekID: String?
    var textFieldShouldBecomeFirstResponder = false
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == CSSearchableItemActionType {
            if let userInfo = activity.userInfo {
                let selectedProfile = userInfo[CSSearchableItemActivityIdentifier] as! String
                name = selectedProfile
                newProfile(withName: name)
                print(selectedProfile)
            }
        }
    }
    
    override func viewDidLoad() {
        if textFieldShouldBecomeFirstResponder {
            searchTextField.becomeFirstResponder()
        }
        stackView.isHidden = true
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.autocorrectionType = .no
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.clearsOnBeginEditing = true
        
        let width = sqrt(self.view.bounds.size.width)*3.05
        var frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: width))
        
        
        loadingAnimation = NVActivityIndicatorView(frame: frame, type: .ballPulse, color: UIColor.black, padding: nil)
        loadingAnimation.center = self.view.center
        self.view.addSubview(loadingAnimation)
        loadingAnimation.hidesWhenStopped = true
        loadingAnimation.startAnimation()
        
        repeatButton = UIButton(frame: frame)
        repeatButton.addTarget(self, action: #selector(self.update), for: .touchUpInside)
        repeatButton.center = self.view.center
        repeatButton.center.y+=self.view.bounds.size.width/3
        repeatButton.setImage(UIImage(imageLiteralResourceName: "Synchronize.png"), for: UIControlState())
        self.view.addSubview(repeatButton)
        
        frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.size.width, height: 100))
        repeatLabel = UILabel(frame: frame)
        repeatLabel.text = "Oops!\nSomething went wrong"
        let fontSize = self.view.bounds.size.width/15
        repeatLabel.font = repeatLabel.font.withSize(fontSize)
        repeatLabel.numberOfLines = 3
        repeatLabel.center = self.view.center
        repeatLabel.center.y-=self.view.bounds.size.width/6
        repeatLabel.textAlignment = .center
        self.view.addSubview(repeatLabel)
        noIDLabel = UILabel(frame: frame)
        noIDLabel.text = "No channel found!\nSearch for something else"
        noIDLabel.font = noIDLabel.font.withSize(fontSize)
        noIDLabel.numberOfLines = 3
        noIDLabel.center = self.view.center
        noIDLabel.textAlignment = .center
        self.view.addSubview(noIDLabel)
        
        shouldShowError(false)
        
        searchTextField.layer.borderColor = UIColor.black.cgColor
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.cornerRadius = 5
        
        visualEffect.frame = self.view.bounds
        visualEffect.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.bounds = self.view.bounds
        imageView.center = self.view.center
        self.view.addSubview(imageView)
        self.view.addSubview(visualEffect)
        self.view.sendSubview(toBack: visualEffect)
        self.view.sendSubview(toBack: imageView)
        visualEffect.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
        
        thumbnailImageView.frame.size = CGSize(width: self.view.bounds.size.width/3, height: self.view.bounds.size.width/3)
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = UIColor.black.cgColor
        thumbnailImageView.clipsToBounds = true
        
        if showNewProfile {
            if peekID != nil {
                name = peekID!
            } else if store.store.count > 0 {
                name = store.store[0].id
            } else {
                name = Public.id
            }
            newProfile(withName: name)
            print("newprofilecalled")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateBookmark()
        
    }
    
    @IBAction func tapGestureRecognizer(_ sender: AnyObject) {
        self.view.endEditing(true)
    }
    
    @IBAction func shareButton(_ sender: AnyObject) {
        guard !self.stackView.isHidden else { return }
        let firstActivityItem = "\(self.channelNameLabel.text!) subscriber count is \(self.liveSubscriberCountLabel.text!) - via SubTracker. Download at http://tinyurl.com/hljn24l"
        
        
        
        
        let window = UIApplication.shared.delegate!.window!!
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        let windowImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //now position the image x/y away from the top-left corner to get the portion we want
        
        var size = self.stackView.frame.size
        size.height+=40
        size.width+=20
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        windowImage?.draw(at: CGPoint(x: -self.stackView.frame.origin.x+10, y: -self.stackView.frame.origin.y+20))
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let secondActivityItem = image
        
        let activityViewController = UIActivityViewController(activityItems: [firstActivityItem, secondActivityItem], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender.view
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        activityViewController.excludedActivityTypes = [
            UIActivityType.postToWeibo,
            UIActivityType.airDrop,
            UIActivityType.print,
            UIActivityType.assignToContact,
            UIActivityType.addToReadingList,
            UIActivityType.postToFlickr,
            UIActivityType.postToVimeo,
            UIActivityType.postToTencentWeibo
        ]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func saveProfile(_ sender: AnyObject) {
        if self.repeatLabel.isHidden {
            updateBookmark(true)
        }
    }
    
    func updateBookmark(_ changeState: Bool? = nil) {
        let profileInStore = self.store.store.filter{$0.id == Public.id}.first
        if let profileInStore = profileInStore {
            if changeState == nil {
                self.bookmarkButton.image = UIImage(imageLiteralResourceName: "BookmarkFilled.png")
            } else {
                let index = self.store.store.index(of: profileInStore)
                self.store.store.remove(at: index!)
                self.bookmarkButton.image = UIImage(imageLiteralResourceName: "Bookmark.png")
            }
        } else {
            if changeState == nil {
                self.bookmarkButton.image = UIImage(imageLiteralResourceName: "Bookmark.png")
            } else {
                let subscriberProfile = SubscriberProfile(image: self.thumbnailImageView.image!, channelName: self.channelNameLabel.text!, id: Public.id, subscriberCount: self.liveSubscriberCountLabel.text!)
                self.store.store.append(subscriberProfile)
                self.bookmarkButton.image = UIImage(imageLiteralResourceName: "BookmarkFilled.png")
            }
        }
    }
    
    func shouldShowError(_ isTrue: Bool, error: Error? = nil) {
        if isTrue {
            if let errorType = error {
                switch errorType {
                case .idError:
                    self.noIDLabel.isHidden = false
                default:
                    self.repeatLabel.isHidden = false
                    self.repeatButton.isHidden = false
                }
            }
        } else {
            self.repeatLabel.isHidden = true
            self.repeatButton.isHidden = true
            self.noIDLabel.isHidden = true
        }
    }
    
    func update() {
        newProfile(withName: name)
    }
    
    func newProfile(withName name: String) {
        print("newprofile")
        self.name = name
        timer?.invalidate()
        timer = nil
        shouldShowError(false)
        self.stackView.isHidden = true
        loadingAnimation.startAnimation()
        var newName = name
        if let id = idStore[name] {
            newName = id
        }
        YoutubeAPI.parseProfile(forName: newName, completionHandler: { result -> Void in
            switch result {
            case let .success(result):
                print("success")
                DispatchQueue.main.async {
                    let subscriberDictionary = result as! [String: AnyObject]
                    self.updateView(withValues: subscriberDictionary)
                    
                    if newName != subscriberDictionary["id"] as! String {
                        var store = self.idStore
                        store[name] = (subscriberDictionary["id"] as! String)
                        UserDefaults.standard.set(store, forKey: "idStore")
                    }
                    if let profile = self.store.store.filter({ $0.id == subscriberDictionary["id"] as! String }).first {
                        profile.image = subscriberDictionary["image"] as! UIImage
                        profile.channelName = subscriberDictionary["channelName"] as! String
                        profile.subscriberCount = subscriberDictionary["liveSubscriberCount"] as! String
                    }
                    
                    let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
                    searchableItemAttributeSet.title = (subscriberDictionary["channelName"] as! String)
                    let data = NSData(data: UIImagePNGRepresentation(subscriberDictionary["image"] as! UIImage)!) as Data
                    searchableItemAttributeSet.thumbnailData = data
                    let keywords = subscriberDictionary["channelName"] as! String
                    searchableItemAttributeSet.keywords =
                        keywords.components(separatedBy: " ")
                    let searchableItem = CSSearchableItem(uniqueIdentifier: (subscriberDictionary["id"] as! String), domainIdentifier: "channels", attributeSet: searchableItemAttributeSet)
                    CSSearchableIndex.default().indexSearchableItems([searchableItem], completionHandler: { (ErrorType) -> Void in
                        if (ErrorType != nil) {
                            print("indexing failed \(ErrorType)")
                        }
                    })
                    var timer = 2.0
                    let subCount = subscriberDictionary["liveSubscriberCount"] as! String
                    if subCount.characters.count < 3 {
                        timer = 40
                    } else if subCount.characters.count < 4 {
                        timer = 20
                    } else if subCount.characters.count < 5 {
                        timer = 10
                    } else if subCount.characters.count < 6 {
                        timer = 5
                    } else if subCount.characters.count < 7 {
                        timer = 3
                    }
                    
                    self.stackView.isHidden = false
                    Public.id = subscriberDictionary["id"] as! String
                    self.updateBookmark()
                    if self.peekID == nil {
                        self.timer = Timer.scheduledTimer(timeInterval: timer, target: self, selector: #selector(self.updateLiveSubscriberCount), userInfo: nil, repeats: true)
                    }
                    
                    self.loadingAnimation.stopAnimation()
                }
            case let .failure(error):
                print(error)
                DispatchQueue.main.async {
                    self.shouldShowError(true, error: error)
                    self.loadingAnimation.stopAnimation()
                }
            }
        })
    }
    
    func updateLiveSubscriberCount() {
        print(Date())
        print(channelNameLabel.text!)
        YoutubeAPI.fetchYoutubeData(forID: Public.id, parameters: [.data], completionHandler: { result -> Void in
            switch result {
            case let .success(result): self.updateView(withValues: result)
            case let .failure(error): print(error)
            }
        })
    }
    
    func updateView(withValues values: [String: Any]) {
        print("update")
        if let channel = values["channelName"] as? String  { self.channelNameLabel.text = channel }
        if let liveSubCount = values["liveSubscriberCount"] as? String { self.liveSubscriberCountLabel.text = liveSubCount }
        if let views = values["viewCount"] as? String { self.viewsCountLabel.text = views }
        if let videos = values["videoCount"] as? String { self.videoCountLabel.text = videos }
        if let image = values["image"] as? UIImage {
            self.imageView.image = image
            self.thumbnailImageView.image = image
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Bookmarks" {
            let navController = segue.destination as! UINavigationController
            let bookmarksViewController = navController.topViewController as! BookmarksTableViewController
            bookmarksViewController.store = self.store
            bookmarksViewController.previousProfile = Public.id
            bookmarksViewController.delegate = self
        }
    }
}

extension SubscriberCountViewController: UITextFieldDelegate {
    func searchTextFieldBecomeFirstResponder() {
        if let textField = searchTextField {
            textField.becomeFirstResponder()
        }
        textFieldShouldBecomeFirstResponder = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        name = textField.text!
        newProfile(withName: name)
        return false
    }
}

extension SubscriberCountViewController: SendIdDelegate {
    func sendData(_ data: String) {
        name = data
        newProfile(withName: name)
        searchTextField.text = ""
    }
}
