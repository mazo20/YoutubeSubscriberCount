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
public enum Result {
    case Success(AnyObject)
    case Failure(ErrorType)
}
public enum Error: ErrorType {
    case PhotoError
    case StuckSubError
    case DataError
    case IDError
    case ConstructingError
    case JSONError
}
public enum DataParameters {
    case Photo
    case Data
    case StuckSubscriberCount
}

public struct YoutubeAPI {
    private static let baseURLString = "https://www.googleapis.com/youtube/v3/"
    private static let APIKey = ["AIzaSyBKoz_46nVMrkdZqYmgs-q2uhu81AEKEoc", "AIzaSyAaRTD6E--TcqXQ6u0vz3tbds8JmT4obnM", "AIzaSyAgG6SUKqjUj5NJejwXrUIphrePzjCVZdc", "AIzaSyCLuq2COJS2ZOybx8RTlIZ5_ho3w8wdIWI"]
    
    static func youtubeURL(method method: Method, part: [String], parameters:[String: String]) -> NSURL {
        let components = NSURLComponents(string: baseURLString + method.rawValue)!
        var queryItems = [NSURLQueryItem]()
        let joinedPart = part.joinWithSeparator(",")
        var item = NSURLQueryItem(name: "part", value: joinedPart)
        queryItems.append(item)
        for (key, value) in parameters {
            let item = NSURLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        let random = Int(arc4random_uniform(4))
        item = NSURLQueryItem(name: "key", value: APIKey[random])
        queryItems.append(item)
        components.queryItems = queryItems
        
        return components.URL!
    }
    
    static func photoForId(id: String, completionHandler: (Result) -> Void ) {
        var returnData = [String]()
        let url = youtubeURL(method: .Channels, part: ["snippet"], parameters: ["id": id])
        jsonSerialization(url, completionHandler:  { dataResult -> Void in
            switch dataResult {
            case let .Success(result):
                if let items = result["items"] as? [[String: AnyObject]] where items.count > 0,
                    let snippet = items[0]["snippet"] as? NSDictionary,
                    thumbnails = snippet["thumbnails"] as? NSDictionary,
                    image = thumbnails["medium"] as? NSDictionary,
                    urlString = image["url"] as? String,
                    title = snippet["title"] as? String {
                        returnData.append(urlString)
                        returnData.append(title)
                        completionHandler(.Success(returnData))
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
        let url = youtubeURL(method: .Channels, part: ["statistics"], parameters: ["id": id])
        jsonSerialization(url, completionHandler: { dataResult -> Void in
            switch dataResult {
            case let .Success(result):
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                if let items = result["items"] as? [[String: AnyObject]] where items.count > 0,
                    let statistics = items[0]["statistics"] as? [String: AnyObject],
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
            case let .Failure(error):
                print(error)
                completionHandler(.Failure(Error.DataError))
            }
        })
    }
    
    static func idForName(name: String, completionHandler: (Result) -> Void ){
        if name.characters.count == 24 {
            print("ID already known")
            completionHandler(.Success(name))
        } else {
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
                    completionHandler(.Failure(error))
                }
            })
        }
    }
    
    static func jsonSerialization(url: NSURL, completionHandler: (Result) -> Void) {
        let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            do {
                if let myData = data, let result = try NSJSONSerialization.JSONObjectWithData(myData, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] {
                    completionHandler(.Success(result))
                } else {
                    completionHandler(.Failure(Error.JSONError))
                }
            } catch {
                completionHandler(.Failure(Error.JSONError))
            }
        })
        task.resume()
    }
    
    public static func parseAllData(forName: String, completionHandler: (Result) -> Void) {
        idForName(forName, completionHandler: { idResult -> Void in
            switch idResult {
            case let .Success(result):
                let id = result as! String
                parseData(forID: id, parameters: [.Data, .Photo, .StuckSubscriberCount], completionHandler: { dataResult -> Void in
                    switch dataResult {
                    case let .Success(result):
                        completionHandler(.Success(result as! [String: AnyObject]))
                    case let .Failure(error):
                        print(error)
                        switch error {
                            case Error.JSONError:
                            completionHandler(.Failure(error))
                            default:
                            completionHandler(.Failure(Error.ConstructingError))
                        }
                    }
                })
            case let .Failure(error):
                print(error)
                switch error {
                case Error.IDError:
                    completionHandler(.Failure(error))
                default:
                    completionHandler(.Failure(Error.ConstructingError))
                }
            }
        })
    }
    public static func parseData(forID id: String, parameters: [DataParameters], completionHandler: (Result) -> Void) {
        var subscriberDictionary = [String: AnyObject]()
        let group = dispatch_group_create()
        if parameters.contains(.Photo) {
            dispatch_group_enter(group)
            photoForId(id, completionHandler: { photoResult -> Void in
                switch photoResult {
                case let .Success(result):
                    let array = result as! [String]
                    let url = NSURL(string: array[0])
                    let imageData = NSData(contentsOfURL: url!)
                    subscriberDictionary["image"] = UIImage(data: imageData!)
                    subscriberDictionary["channelName"] = array[1]
                    dispatch_group_leave(group)
                case let .Failure(error):
                    print(error)
                    dispatch_group_leave(group)
                }
            })
        }
        if parameters.contains(.Data) {
            dispatch_group_enter(group)
            dataForId(id, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .Success(result):
                    if let array = result as? [String] {
                        subscriberDictionary["liveSubscriberCount"] = array[0]
                        subscriberDictionary["viewsCount"] = array[1]
                        subscriberDictionary["videosCount"] = array[2]
                        dispatch_group_leave(group)
                    }
                case let .Failure(error):
                    print(error)
                    dispatch_group_leave(group)
                }
            })
        }
        if parameters.contains(.StuckSubscriberCount) {
            dispatch_group_enter(group)
            stuckSubscriberCountForId(id, completionHandler: { subsResult -> Void in
                switch subsResult {
                case let .Success(result):
                    subscriberDictionary["stuckSubscriberCount"] = result as! String
                    dispatch_group_leave(group)
                case let .Failure(error):
                    print(error)
                    dispatch_group_leave(group)
                }
            })
        }
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            subscriberDictionary["id"] = id
            if subscriberDictionary["stuckSubscriberCount"] == nil && parameters.count == 3{
                if let live = subscriberDictionary["liveSubscriberCount"] as? String {
                    subscriberDictionary["stuckSubscriberCount"] = live
                }
            }
            if parameters.count == 3 {
                if subscriberDictionary.count == 7 {
                    completionHandler(.Success(subscriberDictionary))
                } else {
                    completionHandler(.Failure(Error.ConstructingError))
                }
            } else {
                completionHandler(.Success(subscriberDictionary))
            }
            
        }
    }
}