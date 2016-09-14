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
    func sendData(_ data: String)
}

class BookmarksTableViewController: UIViewController {
    
    var store: SubscriberProfileStore!
    weak var delegate: SendIdDelegate?
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    
    @IBAction func editButton(_ sender: AnyObject) {
        editButton.title = tableView.isEditing == true ? "Edit" : "Done"
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @IBAction func cancelButton(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        var searchableItems = [CSSearchableItem]()
        for profile in store.store {
            let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            searchableItemAttributeSet.title = profile.channelName
            searchableItemAttributeSet.containerTitle = "test"
            let data = NSData(data: UIImagePNGRepresentation(profile.image)!) as Data
            searchableItemAttributeSet.thumbnailData = data
            searchableItemAttributeSet.keywords = [profile.channelName]
            
            let searchableItem = CSSearchableItem(uniqueIdentifier: profile.id, domainIdentifier: "channels", attributeSet: searchableItemAttributeSet)
            
            searchableItems.append(searchableItem)
        }
        CSSearchableIndex.default().indexSearchableItems(searchableItems, completionHandler: { (ErrorType) -> Void in
            if (ErrorType != nil) {
                print("indexing failed \(ErrorType)")
            }
        })
    }
}
extension SubscriberProfileStore {
    func moveProfile(_ fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex else { return }
        let profile = store[fromIndex]
        store.remove(at: fromIndex)
        store.insert(profile, at: toIndex)
    }
}

extension BookmarksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            store.store.remove(at: (indexPath as NSIndexPath).row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        store.moveProfile((sourceIndexPath as NSIndexPath).row, toIndex: (destinationIndexPath as NSIndexPath).row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.store.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriberCell", for: indexPath) as! SubscriberCell
        cell.channelName.text = store.store[(indexPath as NSIndexPath).row].channelName
        cell.thumbnailImageView.image = store.store[(indexPath as NSIndexPath).row].image
        cell.thumbnailImageView.layer.cornerRadius = 5
        cell.thumbnailImageView.layer.masksToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.sendData(store.store[(indexPath as NSIndexPath).row].id)
        DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "First three channels will be shown in a widget"
    }
}
