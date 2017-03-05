//
//  YoutubeAPI.swift
//  SubscriberCount
//
//  Created by Maciej Kowalski on 30.08.2016.
//  Copyright © 2016 Maciej Kowalski. All rights reserved.
//

import UIKit
import Alamofire

enum Method: String {
    case Search = "search?"
    case Channels = "channels?"
}
public enum Result<T> {
    case success(T)
    case failure(Error)
}
public enum Error: String {
    case idError
    case constructingError
}
public enum DataParameters: String {
    case photo = "snippet"
    case data = "statistics"
}

extension String {
    var stringInDecimal: String? {
        guard let number = Int64(self) else { return nil }
        let nsnumber = NSNumber(value: number)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: nsnumber)
    }
}

public struct YoutubeAPI {
    fileprivate static let baseURLString = "https://www.googleapis.com/youtube/v3/"
    fileprivate static let APIKey = "AIzaSyBKoz_46nVMrkdZqYmgs-q2uhu81AEKEoc"
    
    fileprivate static func youtubeURL(method: Method, part: [String], parameters:[String: String]) -> URL {
        var components = URLComponents(string: baseURLString + method.rawValue)!
        var queryItems = [URLQueryItem]()
        let joinedPart = part.joined(separator: ",")
        var item = URLQueryItem(name: "part", value: joinedPart)
        queryItems.append(item)
        for (key, value) in parameters {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        item = URLQueryItem(name: "key", value: APIKey)
        queryItems.append(item)
        components.queryItems = queryItems
        
        return components.url!
    }
    
    fileprivate static func fetchID(forName name: String, completionHandler: @escaping (Result<String>) -> Void ){
        if name.characters.count == 24 {
            print("ID already known")
            completionHandler(.success(name))
        } else {
            let url = youtubeURL(method: .Search, part: ["snippet"], parameters: ["q": name, "type": "channel"])
            Alamofire.request(url).responseJSON { response in
                guard let JSON = response.result.value as? [String: AnyObject] else {
                    completionHandler(.failure(Error.constructingError))
                    return
                }
                if let pageInfo = JSON["pageInfo"] as? NSDictionary,
                    let totalResults = pageInfo["totalResults"] as? Int , totalResults > 0,
                    let items = JSON["items"] as? [[String:AnyObject]] , items.count > 0,
                    let snippet = items[0]["snippet"] as? NSDictionary,
                    let id = snippet["channelId"] as? String {
                    for items in snippet {
                        dump(items)
                    }
                    completionHandler(.success(id))
                } else {
                    completionHandler(.failure(Error.idError))
                }
            }
        }
    }
    
    static func fetchYoutubeData(forID id: String, parameters: [String], completionHandler: @escaping ([String: Any]) -> Void) {
        var subscriberDictionary = [String: Any]()
        let url = youtubeURL(method: .Channels, part: parameters, parameters: ["id": id])
        Alamofire.request(url).responseJSON { response in
            if let JSON = response.result.value as? [String: AnyObject], let items = JSON["items"] as? [[String: AnyObject]] , items.count > 0 {
                if let statistics = items[0]["statistics"] as? NSDictionary,
                    let viewCount = statistics["viewCount"] as? String,
                    let views = viewCount.stringInDecimal,
                    let subscriberCount = statistics["subscriberCount"] as? String,
                    let liveSubscriberCount = subscriberCount.stringInDecimal,
                    let videoCount = statistics["videoCount"] as? String,
                    let videos = videoCount.stringInDecimal {
                    subscriberDictionary["liveSubscriberCount"] = liveSubscriberCount
                    subscriberDictionary["viewCount"] = views
                    subscriberDictionary["videoCount"] = videos
                    subscriberDictionary["id"] = id
                }
                if let snippet = items[0]["snippet"] as? NSDictionary,
                    let thumbnails = snippet["thumbnails"] as? NSDictionary,
                    let image = thumbnails["medium"] as? NSDictionary,
                    let urlString = image["url"] as? String,
                    let title = snippet["title"] as? String,
                    let url = URL(string: urlString),
                    let imageData = try? Data(contentsOf: url) {
                    subscriberDictionary["image"] = UIImage(data: imageData)
                    subscriberDictionary["channelName"] = title
                }
            }
            completionHandler(subscriberDictionary)
        }
    }
    
    public static func parseProfile(forName name: String, completionHandler: @escaping (Result<Any>) -> Void) {
        fetchID(forName: name, completionHandler: { idResult -> Void in
            switch idResult {
            case let .success(id):
                fetchYoutubeData(forID: id, parameters: ["snippet", "statistics"], completionHandler: { result -> Void in
                    if result.count != 6  {
                        completionHandler(.failure(Error.constructingError))
                    } else {
                        completionHandler(.success(result))
                    }
                })
            case let .failure(error): completionHandler(.failure(error))
            }
        })
    }
}
