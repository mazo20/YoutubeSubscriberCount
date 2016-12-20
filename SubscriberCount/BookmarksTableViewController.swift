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
import DZNEmptyDataSet

protocol SendIdDelegate: class {
    func sendData(_ data: String)
}

class BookmarksTableViewController: UIViewController {
    
    var store: SubscriberProfileStore!
    weak var delegate: SendIdDelegate?
    var previousProfile: String!
    var didPreview = false
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    
    @IBAction func editButton(_ sender: AnyObject) {
        editButton.title = tableView.isEditing == true ? NSLocalizedString("Edit", comment: "Edit") : NSLocalizedString("Done", comment: "Done")
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @IBAction func cancelButton(_ sender: AnyObject) {
        if didPreview {
            self.delegate?.sendData(previousProfile)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        self.tableView.tableFooterView = UIView()
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
    }
}

extension BookmarksTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            store.store.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        store.moveProfile(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.store.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriberCell", for: indexPath) as! SubscriberCell
        cell.channelName.text = store.store[indexPath.row].channelName
        cell.thumbnailImageView.image = store.store[indexPath.row].image
        cell.thumbnailImageView.layer.cornerRadius = 5
        cell.thumbnailImageView.layer.masksToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async(execute: {
            self.delegate?.sendData(self.store.store[indexPath.row].id)
            self.dismiss(animated: true, completion: nil)
        })
    }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return store.store.count == 0 ? nil : NSLocalizedString("FirstThreeChannels", comment: "First three channels will be shown in a widget")
    }
}

extension BookmarksTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        dismiss(animated: true, completion: nil)
    }
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        didPreview = true
        var point = location
        point.y+=tableView.contentOffset.y
        guard let indexPath = self.tableView.indexPathForRow(at: point),
            let cell = tableView.cellForRow(at: indexPath),
            let mainVC = storyboard?.instantiateViewController(withIdentifier: "MainViewController") as? SubscriberCountViewController,
            let selectedProfileID = store.store[indexPath.row].id else {return nil}
        
        mainVC.store = store
        mainVC.timer?.invalidate()
        mainVC.peekID = selectedProfileID
        self.delegate?.sendData(selectedProfileID)
        previewingContext.sourceRect = cell.frame
        previewingContext.sourceRect.origin.y-=tableView.contentOffset.y
        return mainVC
    }
}

extension BookmarksTableViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(imageLiteralResourceName: "BookmarkEmptyScreen.png")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No bookmarks", attributes: [NSForegroundColorAttributeName: UIColor.darkGray, NSFontAttributeName: UIFont.systemFont(ofSize: 25)])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Save your Youtube channels to have quick access and to use widgets", attributes: [NSForegroundColorAttributeName: UIColor.darkGray, NSFontAttributeName: UIFont.systemFont(ofSize: 15)])
    }
}
