//
//  YoutubeAPI.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import Foundation

enum Method: String {
    case Search = "search?"
    case Channels = "channels?"
}

struct YoutubeAPI {
    private static let baseURLString = "https://www.googleapis.com/youtube/v3/"
    private static let APIKey = "AIzaSyCLuq2COJS2ZOybx8RTlIZ5_ho3w8wdIWI"
    
    static func youtubeURL(method method:Method, part: [String],  parameters:[String: String]) -> NSURL {
        let components = NSURLComponents(string: baseURLString + method.rawValue)!
        var queryItems = [NSURLQueryItem]()
        let joinedPart = part.joinWithSeparator(",")
        var item = NSURLQueryItem(name: "part", value: joinedPart)
        queryItems.append(item)
        for (key, value) in parameters {
            let item = NSURLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        item = NSURLQueryItem(name: "key", value: APIKey)
        queryItems.append(item)
        components.queryItems = queryItems
        
        return components.URL!
    }
    
    static func dataForId(id: String) -> [String] {
        var returnData = [String]()
        let url = youtubeURL(method: .Channels, part: ["statistics", "snippet"], parameters: ["id": id])
        if let data = jsonSerialization(url) {
            if let items = data["items"] as? [[String: AnyObject]] {
                if items.count > 0 {
                    if let snippet = items[0]["snippet"] as? NSDictionary {
                        if let thumbnails = snippet["thumbnails"] as? NSDictionary {
                            if let image = thumbnails["high"] as? NSDictionary {
                                if let urlString = image["url"] as? String {
                                    returnData.append(urlString)
                                    print("High profile picture not avaible")
                                }
                            } else if let image = thumbnails["medium"] as? NSDictionary {
                                if let urlString = image["url"] as? String {
                                    returnData.append(urlString)
                                    print("Medium prifile picture not availble")
                                }
                            } else if let image = thumbnails["default"] as? NSDictionary {
                                if let urlString = image["url"] as? String {
                                    returnData.append(urlString)
                                }
                            }
                        }
                    }
                    if let statistics = items[0]["statistics"] as? [String: AnyObject] {
                        if let subscriberCount = statistics["subscriberCount"] as? String {
                            if let number = Int(subscriberCount) {
                                let numberFormatter = NSNumberFormatter()
                                numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                                if let finalNumber = numberFormatter.stringFromNumber(number) {
                                    returnData.append(finalNumber)
                                }
                            }
                            
                            
                        }
                    }

                }
            }
        }
    }
    
    static func idForName(name: String) -> [String] {
        let url = youtubeURL(method: .Search, part: ["snippet"], parameters: ["q": name, "type": "channel"])
        if let data = jsonSerialization(url) {
            if let pageInfo = data["pageInfo"] as? NSDictionary {
                if let totalResults = pageInfo["totalResults"] as? Int {
                    if totalResults == 0 {
                        return ["Invalid name"]
                    } else {
                        if let items = data["items"] as? [[String:AnyObject]] {
                            if items.count > 0 {
                                if let snippet = items[0]["snippet"] as? NSDictionary {
                                    if let id = snippet["channelId"] as? String, let title = snippet["title"] as? String {
                                        return [id, title]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return ["Data error"]
    }
    
    static func jsonSerialization(url: NSURL) -> [String: AnyObject]? {
        var result: [String: AnyObject]?
        let semaphore = dispatch_semaphore_create(0)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            do {
                if let myData = data, let jsonResult = try NSJSONSerialization.JSONObjectWithData(myData, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] {
                    result = jsonResult
                    dispatch_semaphore_signal(semaphore)
                } else {
                    dispatch_semaphore_signal(semaphore)
                }
            } catch {
                print("JSON error: \(error)")
                dispatch_semaphore_signal(semaphore)
            }
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return result
    }
    
    
    
    
}