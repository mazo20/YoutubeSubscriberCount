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
        print("reloadData")
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        // Do any additional setup after loading the view from its nib.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        
        print("widget")
        
        completionHandler(NCUpdateResult.newData)
    }
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: 0, height: 95)
            //self.tableView.separatorStyle = .none
        } else {
            let count = names?.count
            if let count = count {
                self.preferredContentSize = CGSize(width: 0, height: count * 100)
            } else {
                self.preferredContentSize = tableView.contentSize
            }
            //self.tableView.separatorStyle = .singleLine
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
        let count = names?.count
        if let count = count {
            if count == 0 { return 1 }
            return count
        }
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.preferredContentSize = tableView.contentSize
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriberCell", for: indexPath) as! SubscriberCell
        if images?.count == 0 {
            cell.channelName.text = "Setup required"
            return cell
        }
        if let photo = images?[indexPath.row] {
            let image = UIImage(data: photo)
            cell.thumbnailImageView.image = image!
            cell.thumbnailImageView.layer.cornerRadius = 5
            cell.thumbnailImageView.clipsToBounds = true
        }
        if let subs = subs?[indexPath.row] {
            cell.subscriberCount.text = subs
            print(subs)
            print("test")
        }
        if let id = ids?[indexPath.row] {
            print(id)
            YoutubeAPI.parseData(forID: id, parameters: [.data], completionHandler: { result -> Void in
                switch result {
                case let .success(result):
                    let dict = result
                    let sub = dict["liveSubscriberCount"] as! String
                    cell.subscriberCount.text = sub
                    self.subs?[indexPath.row] = sub
                    self.defaults?.setValue(self.subs, forKey: "subs")
                    
                case let .failure(error):
                    print(error)
                }
            })
        }
        if let name = names?[indexPath.row] {
            cell.channelName.text = name
            print(name)
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = URL(string: "SubTracker:/\(ids![indexPath.row])")
        print(indexPath.row)
        self.extensionContext?.open(url!, completionHandler: nil)
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
}
