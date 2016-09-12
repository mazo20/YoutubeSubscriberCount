//
//  BookmarksTableViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 01.09.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import CoreSpotlight
import MobileCoreServices

protocol SendIdDelegate: class {
    func sendData(data: String)
}

class BookmarksTableViewController: UIViewController {
    
    var store: SubscriberProfileStore!
    weak var delegate: SendIdDelegate?
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    
    @IBAction func editButton(sender: AnyObject) {
        editButton.title = tableView.editing == true ? "Edit" : "Done"
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
    @IBAction func cancelButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewDidLoad() {
        var searchableItems = [CSSearchableItem]()
        for profile in store.store {
            let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            searchableItemAttributeSet.title = profile.channelName
            searchableItemAttributeSet.containerTitle = "test"
            let data = NSData(data: UIImagePNGRepresentation(profile.image)!)
            searchableItemAttributeSet.thumbnailData = data
            searchableItemAttributeSet.keywords = [profile.channelName]
            
            let searchableItem = CSSearchableItem(uniqueIdentifier: profile.id, domainIdentifier: "channels", attributeSet: searchableItemAttributeSet)
            
            searchableItems.append(searchableItem)
        }
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(searchableItems, completionHandler: { (ErrorType) -> Void in
            if (ErrorType != nil) {
                print("indexing failed \(ErrorType)")
            }
        })
    }
}
extension SubscriberProfileStore {
    func moveProfile(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex else { return }
        let profile = store[fromIndex]
        store.removeAtIndex(fromIndex)
        store.insert(profile, atIndex: toIndex)
    }
}

extension BookmarksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            store.store.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        store.moveProfile(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.store.count
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SubscriberCell", forIndexPath: indexPath) as! SubscriberCell
        cell.channelName.text = store.store[indexPath.row].channelName
        cell.thumbnailImageView.image = store.store[indexPath.row].image
        cell.thumbnailImageView.layer.cornerRadius = 5
        cell.thumbnailImageView.layer.masksToBounds = true
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.sendData(store.store[indexPath.row].id)
        dispatch_async(dispatch_get_main_queue(),{
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "First three channels will be shown in a widget"
    }
}
