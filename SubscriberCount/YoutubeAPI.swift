//
//  YoutubeAPI.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit

enum Method: String {
    case Search = "search?"
    case Channels = "channels?"
}
enum Result {
    case Success(AnyObject)
    case Failure(ErrorType)
}
enum Error: ErrorType {
    case PhotoError
    case StuckSubError
    case DataError
    case IDError
    case ConstructingError
    case JSONError
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
    
    static func photoForId(id: String, completionHandler: (Result) -> Void ) {
        let url = youtubeURL(method: .Channels, part: ["snippet"], parameters: ["id": id])
        jsonSerialization(url, completionHandler:  { dataResult -> Void in
            switch dataResult {
            case let .Success(result):
                if let items = result["items"] as? [[String: AnyObject]] where items.count > 0,
                    let snippet = items[0]["snippet"] as? NSDictionary,
                    thumbnails = snippet["thumbnails"] as? NSDictionary,
                    image = thumbnails["medium"] as? NSDictionary,
                    urlString = image["url"] as? String {
                        completionHandler(.Success(urlString))
                } else {
                    completionHandler(.Failure(Error.PhotoError))
                }
            case let .Failure(error):
                print(error)
                completionHandler(.Failure(Error.PhotoError))
            }
        })
    }
    
    static func stuckSubscriberCountForId(id: String, completionHandler: (Result) -> Void ) {
        if let url = NSURL(string: "https://query.yahooapis.com/v1/public/yql?q=SELECT%20*%20FROM%20html%20where%20url%3D%22https%3A%2F%2Fwww.youtube.com%2Fchannel%2F\(id)%2Fabout%22%20%0AAND%20xpath%3D'%2F%2F*%5B%40class%3D%22about-stats%22%5D%2F%2Fb'&format=json") {
            jsonSerialization(url, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .Success(result):
                    if let query = result["query"] as? [String: AnyObject],
                        results = query["results"] as? [String: AnyObject],
                        subscribers = results["b"] as? [String] where subscribers.count > 0 {
                        var numberText = subscribers[0]
                        numberText = numberText.stringByReplacingOccurrencesOfString(",", withString: "")
                        if let number = Int(numberText) {
                            let numberFormatter = NSNumberFormatter()
                            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                            let string = numberFormatter.stringFromNumber(number)
                            completionHandler(.Success(string!))
                        }
                    } else {
                        completionHandler(.Failure(Error.StuckSubError))
                    }
                case let .Failure(error):
                    print(error)
                    completionHandler(.Failure(Error.StuckSubError))
                }
            })
        }
    }
    
    static func dataForId(id: String, completionHandler: (Result) -> Void ){
        var returnData = [String]()
        let url = youtubeURL(method: .Channels, part: ["statistics", "snippet"], parameters: ["id": id])
        jsonSerialization(url, completionHandler: { dataResult -> Void in
            switch dataResult {
            case let .Success(result):
                if let items = result["items"] as? [[String: AnyObject]] where items.count > 0, let snippet = items[0]["snippet"] as? NSDictionary, title = snippet["title"] as? String{
                    returnData.append(title)
                    let numberFormatter = NSNumberFormatter()
                    numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                    if let statistics = items[0]["statistics"] as? [String: AnyObject],
                        subscriberCount = statistics["subscriberCount"] as? String,
                        subscriberNumber = Int(subscriberCount),
                        finalSubscriber = numberFormatter.stringFromNumber(subscriberNumber),
                        viewCount = statistics["viewCount"] as? String,
                        viewNumber = Int(viewCount),
                        finalView = numberFormatter.stringFromNumber(viewNumber),
                        videoCount = statistics["videoCount"] as? String,
                        videoNumber = Int(videoCount),
                        finalVideo = numberFormatter.stringFromNumber(videoNumber) {
                            returnData.append(finalSubscriber)
                            returnData.append(finalView)
                            returnData.append(finalVideo)
                            completionHandler(.Success(returnData))
                    } else {
                        completionHandler(.Failure(Error.DataError))
                    }
                } else {
                    completionHandler(.Failure(Error.DataError))
                }
            case let .Failure(error):
                print(error)
                completionHandler(.Failure(Error.DataError))
            }
        })
    }
    
    static func idForName(name: String, completionHandler: (Result) -> Void ){
        let url = youtubeURL(method: .Search, part: ["snippet"], parameters: ["q": name, "type": "channel"])
        jsonSerialization(url, completionHandler: { dataResult -> Void in
            switch dataResult {
            case let .Success(result):
                if let pageInfo = result["pageInfo"] as? NSDictionary,
                    totalResults = pageInfo["totalResults"] as? Int where totalResults > 0,
                    let items = result["items"] as? [[String:AnyObject]] where items.count > 0,
                    let snippet = items[0]["snippet"] as? NSDictionary,
                    id = snippet["channelId"] as? String {
                    completionHandler(.Success(id))
                } else {
                    completionHandler(.Failure(Error.IDError))
                }
            case let .Failure(error):
                print(error)
                completionHandler(.Failure(Error.IDError))
            }
        })
    }
    
    static func jsonSerialization(url: NSURL, completionHandler: (Result) -> Void) {
        var result: [String: AnyObject]?
        let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            do {
                if let myData = data, let jsonResult = try NSJSONSerialization.JSONObjectWithData(myData, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] {
                    result = jsonResult
                    completionHandler(.Success(result!))
                } else {
                    completionHandler(.Failure(Error.JSONError))
                }
            } catch {
                completionHandler(.Failure(Error.JSONError))
            }
        })
        task.resume()
    }
    
    static func fetchAllData(forName: String, completionHandler: (Result) -> Void) {
        var image: UIImage?
        var data = [String]()
        YoutubeAPI.idForName(forName, completionHandler: { idResult -> Void in
            switch idResult {
            case let .Success(result):
                let id = result as! String
                publicId = id
                let group = dispatch_group_create()
                dispatch_group_enter(group)
                YoutubeAPI.photoForId(id, completionHandler: { photoResult -> Void in
                    switch photoResult {
                    case let .Success(result):
                        let url = NSURL(string: result as! String)
                        let imageData = NSData(contentsOfURL: url!)
                        image = UIImage(data: imageData!)
                        dispatch_group_leave(group)
                    case let .Failure(error):
                        print(error)
                        dispatch_group_leave(group)
                    }
                })
                dispatch_group_enter(group)
                YoutubeAPI.dataForId(id, completionHandler: { dataResult -> Void in
                    switch dataResult {
                    case let .Success(result):
                        if let array = result as? [String] {
                            data.append(array[1])
                            data.append(array[0])
                            data.append(array[3])
                            data.append(array[2])
                            dispatch_group_leave(group)
                        }
                    case let .Failure(error):
                        print(error)
                        dispatch_group_leave(group)
                    }
                })
                dispatch_group_enter(group)
                YoutubeAPI.stuckSubscriberCountForId(id, completionHandler: { subsResult -> Void in
                    switch subsResult {
                    case let .Success(result):
                        data.append(result as! String)
                        dispatch_group_leave(group)
                    case let .Failure(error):
                        print(error)
                        dispatch_group_leave(group)
                    }
                    
                })
                dispatch_group_notify(group, dispatch_get_main_queue()) {
                    if data.count == 4 {
                        data.append(data[0])
                    }
                    if data.count == 5 {
                        let sub = SubscriberProfile(image: image, liveSubscriberCount: data[0], channelName: data[1], videosCount: data[2], viewsCount: data[3], stuckSubscriberCount: data[4], id: id)
                        completionHandler(.Success(sub))
                    } else {
                        completionHandler(.Failure(Error.ConstructingError))
                    }
                }
            case let .Failure(error):
                print(error)
                completionHandler(.Failure(Error.ConstructingError))
            }
        })
    }
    static func fetchSomeData(id: String, completionHandler: (Result) -> Void ){
        var data = [String]()
        YoutubeAPI.dataForId(id, completionHandler: { dataResult -> Void in
            switch dataResult {
            case let .Success(result):
                if let array = result as? [String] {
                    data.append(array[1])
                    data.append(array[0])
                    data.append(array[3])
                    data.append(array[2])
                    let sub = SubscriberProfile(image: nil, liveSubscriberCount: data[0], channelName: data[1], videosCount: data[2], viewsCount: data[3], stuckSubscriberCount: nil, id: nil)
                    completionHandler(.Success(sub))
                }
            case let .Failure(error):
                print(error)
                completionHandler(.Failure(Error.DataError))
            }
        })
    }
    
}