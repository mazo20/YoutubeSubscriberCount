//
//  SearchViewController.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 11.03.2017.
//  Copyright © 2017 Maciej Kowalski. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    var profiles = [Int: Any]()
    weak var delegate: SendIdDelegate?
    
    var loadingAnimation: NVActivityIndicatorView!
    var noIDLabel: UILabel!
    
    
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    @IBAction func cancel(_ sender: Any) {
        if searchTextField.isFirstResponder { searchTextField.resignFirstResponder() }
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        searchTextField.becomeFirstResponder()
        searchTextField.delegate = self
        searchTextField.placeholder = NSLocalizedString("EnterChannel", comment: "Enter channel's name or ID")
        
        let width = sqrt(self.view.bounds.size.width)*3.05
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: width))
        loadingAnimation = NVActivityIndicatorView(frame: frame, type: .ballPulse, color: UIColor.black, padding: nil)
        loadingAnimation.center = self.view.center
        self.view.addSubview(loadingAnimation)
        loadingAnimation.hidesWhenStopped = true
        
        noIDLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 150))
        noIDLabel.text = NSLocalizedString("ChannelNotFound", comment: "Channel not found!\nSearch for something else")
        noIDLabel.font = noIDLabel.font.withSize(20)
        noIDLabel.numberOfLines = 3
        noIDLabel.center = self.view.center
        noIDLabel.textAlignment = .center
        self.view.addSubview(noIDLabel)
        noIDLabel.isHidden = true
    }
    
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.00001
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return profiles.count > 0 ? NSLocalizedString("NoMoreChannelsFound", comment: "No more channels found") : ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchCell
        let profile = profiles[indexPath.row] as! [String: Any]
        if let name = profile["channelName"] as? String {
            cell.channelName.text = name
        }
        if let image = profile["image"] as? UIImage {
            cell.thumbnailImageView.image = image
            cell.thumbnailImageView.layer.cornerRadius = 5
            cell.thumbnailImageView.clipsToBounds = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profile = profiles[indexPath.row] as! [String: Any]
        if let id = profile["id"] as? String {
            DispatchQueue.main.async(execute: {
                self.delegate?.sendData(id)
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        
        profiles.removeAll()
        tableView.reloadData()
        loadingAnimation.startAnimation()
        noIDLabel.isHidden = true
        
        YoutubeAPI.fetchIDs(forName: searchTextField.text!, completionHandler: { result -> Void in
            self.profiles = result
            self.tableView.reloadData()
            self.loadingAnimation.stopAnimation()
            if self.profiles.count == 0 { self.noIDLabel.isHidden = false }
        })
        
        return true
    }
}
