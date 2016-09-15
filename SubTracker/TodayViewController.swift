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
import SubscriberCountKit

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var tableView: UITableView!
    
    let id = ["UCtinbF-Q-fVthA0qrFQTgXQ", "UCzuvRWjh7k1SZm1RvqvIx4w", "UC-lHJZR3Gqxm24_Vd_AJ5Yw"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        tableView.contentInset.top = -8
        print("reloadData")
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        self.preferredContentSize = tableView.contentSize
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
        } else {
            self.preferredContentSize = tableView.contentSize
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
        return 3
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriberCell", for: indexPath) as! SubscriberCell
        YoutubeAPI.parseData(forID: id[indexPath.row], parameters: [.data, .photo], completionHandler: { result -> Void in
            switch result {
            case let .success(result):
                let dict = result as! [String: AnyObject]
                cell.thumbnailImageView.image = (dict["image"] as! UIImage)
                cell.thumbnailImageView.layer.cornerRadius = 5
                cell.thumbnailImageView.clipsToBounds = true
                cell.channelName.text = (dict["channelName"] as! String)
                cell.subscriberCount.text = (dict["liveSubscriberCount"] as! String)
            case let .failure(error):
                print(error)
            }
        })
        return cell
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.00001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
}
