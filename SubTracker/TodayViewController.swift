//
//  TodayViewController.swift
//  SubTracker
//
//  Created by Maciej Kowalski on 10.09.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import NotificationCenter
import MobileCoreServices

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var tableView: UITableView!
    
    let defaults = UserDefaults(suiteName: "group.subscriberProfiles")
    var images: [Data]?
    var ids: [String]?
    var names: [String]?
    var subs: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        images = defaults?.object(forKey: "images") as? [Data]
        ids = defaults?.object(forKey: "ids") as? [String]
        names = defaults?.object(forKey: "names") as? [String]
        subs = defaults?.object(forKey: "subs") as? [String]
        
        tableView.allowsSelection = true
        tableView.contentInset.top = -8
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: 0, height: 95)
        } else {
            guard let count = names?.count else {
                self.preferredContentSize = tableView.contentSize
                return
            }
            self.preferredContentSize = CGSize(width: 0, height: count * 100)
        }
    }
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        var margin = defaultMarginInsets
        margin.bottom = 0
        return margin
    }
}

extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names?.count == nil ? 1 : names!.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.preferredContentSize = tableView.contentSize
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriberCell", for: indexPath) as! SubscriberCell
        guard let _ = images else {
            cell.channelName.text = "Bookmark required"
            return cell
        }
        if let photo = images?[indexPath.row] {
            let image = UIImage(data: photo)
            cell.thumbnailImageView.image = image!
            cell.thumbnailImageView.layer.cornerRadius = 5
            cell.thumbnailImageView.clipsToBounds = true
        }
        if let subs = subs?[indexPath.row] { cell.subscriberCount.text = subs }
        if let name = names?[indexPath.row] { cell.channelName.text = name }
        if let id = ids?[indexPath.row] {
            YoutubeAPI.fetchYoutubeData(forID: id, parameters: ["statistics"], completionHandler: { result -> Void in
                let dict = result
                guard let sub = dict["liveSubscriberCount"] as? String else { return }
                cell.subscriberCount.text = sub
                self.subs?[indexPath.row] = sub
                self.defaults?.setValue(self.subs, forKey: "subs")
            })
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let _ = names else { return }
        let url = URL(string: "SubTracker:/\(ids![indexPath.row])")
        self.extensionContext?.open(url!, completionHandler: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
}
