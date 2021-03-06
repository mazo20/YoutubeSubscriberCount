//
//  NVActivityIndicatorViewable.swift
//  NVActivityIndicatorViewDemo
//
//  Created by Basem Emara on 5/26/16.
//  Copyright © 2016 Nguyen Vinh. All rights reserved.
//

import UIKit

/**
 *  UIViewController conforms this protocol to be able to display NVActivityIndicatorView as UI blocker.
 *
 *  This will add functionalities to UIViewController to display and remove UI blocker.
 */
public protocol NVActivityIndicatorViewable { }

public extension NVActivityIndicatorViewable where Self: UIViewController {

    fileprivate var activityRestorationIdentifier: String {
        return "NVActivityIndicatorViewContainer"
    }

    /**
     Create a activity indicator view with specified frame, type, color and padding and start animation.
     
     - parameter size: activity indicator view's size. Default size is 60x60.
     - parameter message: message under activity indicator view.
     - parameter type: animation type, value of NVActivityIndicatorType enum. Default type is BallSpinFadeLoader.
     - parameter color: color of activity indicator view. Default color is white.
     - parameter padding: view's padding. Default padding is 0.
     */
    public func startActivityAnimating(_ size: CGSize? = nil, message: String? = nil, type: NVActivityIndicatorType? = nil, color: UIColor? = nil, padding: CGFloat? = nil) {
        let activityContainer: UIView = UIView(frame: UIScreen.main.bounds)
        
        activityContainer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        activityContainer.restorationIdentifier = activityRestorationIdentifier
        
        let actualSize = size ?? NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE
        let activityIndicatorView = NVActivityIndicatorView(
            frame: CGRect(x: 0, y: 0, width: actualSize.width, height: actualSize.height),
            type: type,
            color: color,
            padding: padding)
        
        activityIndicatorView.center = activityContainer.center
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimation()
        activityContainer.addSubview(activityIndicatorView)
        
        let width = activityContainer.frame.size.width / 3
        if let message = message , !message.isEmpty {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: 30))
            label.center = CGPoint(
                x: activityIndicatorView.center.x,
                y: activityIndicatorView.center.y + actualSize.height)
            label.textAlignment = .center
            label.text = message
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.textColor = activityIndicatorView.color
            activityContainer.addSubview(label)
        }
        
        UIApplication.shared.keyWindow!.addSubview(activityContainer)
    }
    
    /**
     Stop animation and remove from view hierarchy.
     */
    public func stopActivityAnimating() {
        for item in UIApplication.shared.keyWindow!.subviews
            where item.restorationIdentifier == activityRestorationIdentifier {
                item.removeFromSuperview()
        }
    }
    
}
