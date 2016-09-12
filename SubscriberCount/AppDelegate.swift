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
    let store = SubscriberProfileStore()

    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        let viewController = (window?.rootViewController as! UINavigationController).viewControllers[0] as! SubscriberCountViewController
        if !viewController.isBeingPresented() {
            viewController.dismissViewControllerAnimated(true, completion: nil)
        }
        viewController.restoreUserActivityState(userActivity)
        
        return true
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        
        
        var performShortcutDelegate = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            performShortcutDelegate = false
        }
        
        let navController = window?.rootViewController as! UINavigationController
        let subViewController = navController.topViewController as! SubscriberCountViewController
        subViewController.store = store
        
        return performShortcutDelegate
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut(shortcutItem:UIApplicationShortcutItem) -> Bool {
        var succeeded = false
        let viewController = (window?.rootViewController as! UINavigationController).viewControllers[0] as! SubscriberCountViewController
        if !viewController.isBeingPresented() {
            viewController.dismissViewControllerAnimated(true, completion: nil)
        }
        if shortcutItem.type == "search" {
            viewController.searchTextFieldBecomeFirstResponder()
            succeeded = true
        } else if shortcutItem.type == "bookmarks" {
            viewController.performSegueWithIdentifier("Bookmarks", sender: self)
            succeeded = true
        }
        return succeeded
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        let success = store.saveChanges()
        if success {
            print("Saved all of the items")
        } else {
            print("Couldn't save any of the items")
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        guard let shortcut = shortcutItem else { return }
        handleShortcut(shortcut)
        self.shortcutItem = nil
        
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        
        print("- Shortcut property has been set")
        
        handleShortcut(shortcut)
        
        self.shortcutItem = nil
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

