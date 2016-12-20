//
//  AppDelegate.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?
    var url: URL?
    let store = SubscriberProfileStore()

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        let viewController = (window?.rootViewController as! UINavigationController).viewControllers[0] as! SubscriberCountViewController
        if !viewController.isBeingPresented {
            viewController.dismiss(animated: true, completion: nil)
        }
        viewController.restoreUserActivityState(userActivity)
        
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        self.url = url
        _ = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.handleURL), userInfo: nil, repeats: false)
        return true
    }
    func handleURL() {
        guard let url = url else { return }
        let viewController = (window?.rootViewController as! UINavigationController).viewControllers[0] as! SubscriberCountViewController
        if !viewController.isBeingPresented {
            viewController.dismiss(animated: true, completion: nil)
        }
        viewController.newProfile(withName: url.lastPathComponent)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let defaults = UserDefaults(suiteName: "group.subscriberProfiles")
        if defaults?.value(forKey: "timesUsed") == nil {
            defaults?.set(0, forKey: "timesUsed")
        }
        if UserDefaults.standard.value(forKey: "neverRate") == nil {
            UserDefaults.standard.set(false, forKey: "neverRate")
            UserDefaults.standard.set(0, forKey: "numLaunches")
        }
        
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            self.shortcutItem = shortcutItem
            performShortcutDelegate = false
        }
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            _ = self.application(application, open: url, options: [:])
        }
        
        let subViewController = (window?.rootViewController as! UINavigationController).topViewController as! SubscriberCountViewController
        subViewController.store = store
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            _ = self.application(application, open: url, options: [:])
            subViewController.showNewProfile = false
        }
        
        return performShortcutDelegate
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut(_ shortcutItem:UIApplicationShortcutItem) -> Bool {
        var succeeded = false
        let viewController = (window?.rootViewController as! UINavigationController).viewControllers[0] as! SubscriberCountViewController
        if !viewController.isBeingPresented {
            viewController.dismiss(animated: true, completion: nil)
        }
        if shortcutItem.type == "search" {
            viewController.searchTextFieldBecomeFirstResponder()
            succeeded = true
        } else if shortcutItem.type == "bookmarks" {
            viewController.performSegue(withIdentifier: "Bookmarks", sender: self)
            succeeded = true
        }
        return succeeded
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        let success = store.saveChanges()
        if success {
            print("Saved all of the items")
        } else {
            print("Couldn't save any of the items")
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        var size = store.store.count
        if size > 3 { size = 3 }
        for i in 0..<size {
            let defaults = UserDefaults(suiteName: "group.subscriberProfiles")
            let subs = defaults?.object(forKey: "subs") as? [String]
            store.store[i].subscriberCount = subs?[i]
        }
        
        guard let shortcut = shortcutItem else { return }
        _ = handleShortcut(shortcut)
        self.shortcutItem = nil
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        guard let shortcut = shortcutItem else { return }
        _ = handleShortcut(shortcut)
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
