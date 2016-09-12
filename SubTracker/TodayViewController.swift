//
//  TodayViewController.swift
//  SubTracker
//
//  Created by Maciej Kowalski on 10.09.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import NotificationCenter
import SubscriberCountKit

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet var tableView: UITableView!
    
    let id = ["UCtinbF-Q-fVthA0qrFQTgXQ", "UCzuvRWjh7k1SZm1RvqvIx4w", "UC-lHJZR3Gqxm24_Vd_AJ5Yw"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize.height = 150
        print("didload")
        // Do any additional setup after loading the view from its nib.
    }
    override func viewWillAppear(animated: Bool) {
        self.preferredContentSize = tableView.contentSize
        tableView.reloadData()
        print("reloadData")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        print("widget")

        completionHandler(NCUpdateResult.NewData)
    }
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        var margin = defaultMarginInsets
        margin.bottom = 0
        return margin
    }
}

extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SubscriberCell", forIndexPath: indexPath) as! SubscriberCell
        YoutubeAPI.parseData(forID: id[indexPath.row], parameters: [.Data, .Photo], completionHandler: { result -> Void in
            switch result {
            case let .Success(result):
                let dict = result as! [String: AnyObject]
                cell.thumbnailImageView.image = (dict["image"] as! UIImage)
                cell.thumbnailImageView.layer.cornerRadius = 5
                cell.thumbnailImageView.clipsToBounds = true
                cell.channelName.text = (dict["channelName"] as! String)
                cell.subscriberCount.text = (dict["liveSubscriberCount"] as! String)
            case let .Failure(error):
                print(error)
            }
        })
        return cell
    }
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Show all..."
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
}
