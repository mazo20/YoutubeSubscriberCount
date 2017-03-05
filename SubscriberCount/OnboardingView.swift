//
//  OnboardingView.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 25.12.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import OnboardingKit

class OnboardingViewController: UIViewController, OnboardingViewDelegate, OnboardingViewDataSource {
    
    
    @IBOutlet var onboardingView: OnboardingView!
    @IBOutlet var button: UIButton!
    @IBAction func nextButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        onboardingView.delegate = self
        onboardingView.dataSource = self
    }
    
    func onboardingView(_ onboardingView: OnboardingView, configurationForPage page: Int) -> OnboardingConfiguration {
        switch page {
        case 0:
            return OnboardingConfiguration(image: #imageLiteral(resourceName: "LaunchIcon"), itemImage: #imageLiteral(resourceName: "Bookmark"), pageTitle: "Welcome to Subtracker!", pageDescription: "With Subtracker you can quickly check the subscriber count of your favourite Youtubers!")
        default:
            return OnboardingConfiguration(image: #imageLiteral(resourceName: "BookmarkEmptyScreen"), itemImage: #imageLiteral(resourceName: "BookmarkFilled"), pageTitle: "How it works", pageDescription: "Simply enter channel's name or ID to show its sub count. Add a bookmark to save channel for later!")
        }
    }


    

    func numberOfPages() -> Int {
        return 2
    }
}
