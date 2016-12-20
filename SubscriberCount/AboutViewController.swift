//
//  AboutViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 31.10.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class AboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 2 }
        return 1
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AboutCell", for: indexPath)
        cell.detailTextLabel?.text = nil
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = NSLocalizedString("RateOnAppstore", comment: "Rate on Appstore")
            cell.accessoryType = .disclosureIndicator
        case 1:
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("SuggestNewFunction", comment: "Suggest new function")
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = NSLocalizedString("ReportABug", comment: "Report a bug")
                cell.accessoryType = .disclosureIndicator
            }
            
        default:
            cell.textLabel?.text = NSLocalizedString("AppVersion", comment: "App version")
            cell.detailTextLabel?.text = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
            cell.detailTextLabel?.textColor = UIColor.darkGray
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("ShareYourOpinionWithOthers", comment: "Share your opinion with others")
        case 1:
            return NSLocalizedString("ShareYourOpinionWithTheDeveloper", comment: "Share your opinion the developer")
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            UserDefaults.standard.set(true, forKey: "neverRate")
            UserDefaults.standard.setValue(4, forKey: "numLaunches")
            UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/subtracker-youtube-live-subscriber/id1156805104?mt=8")!, options: [:], completionHandler: nil)
            
        } else if indexPath.section == 1{
            let email = MFMailComposeViewController()
            email.mailComposeDelegate = self
            email.setMessageBody("\n\n\n-----------------\nApp version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)\niOS version: \(UIDevice.current.systemVersion)", isHTML: false)
            if indexPath.row == 0 {
                email.setSubject("New function")
            } else {
                email.setSubject("Bug report")
            }
            email.setToRecipients(["maciej.kowalski.developer@gmail.com"])
            
            if MFMailComposeViewController.canSendMail() {
                self.present(email, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Swift.Error?) {
        dismiss(animated: true, completion: nil)
    }
}


