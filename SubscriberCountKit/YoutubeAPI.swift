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
public enum Result<T> {
    case success(T)
    case failure(Error)
}
public enum Error: String {
    case photoError
    case stuckSubError
    case dataError
    case idError
    case constructingError
    case jsonError
}
public enum DataParameters {
    case photo
    case data
    case stuckSubscriberCount
}

extension Dictionary {
    mutating func merge<K, V>(_ dict: [K: V]){
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}
extension Int {
    var stringInDecimal: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(integerLiteral: self))
    }
}

public struct YoutubeAPI {
    fileprivate static let baseURLString = "https://www.googleapis.com/youtube/v3/"
    fileprivate static let APIKey = ["AIzaSyBKoz_46nVMrkdZqYmgs-q2uhu81AEKEoc", "AIzaSyAaRTD6E--TcqXQ6u0vz3tbds8JmT4obnM", "AIzaSyAgG6SUKqjUj5NJejwXrUIphrePzjCVZdc", "AIzaSyCLuq2COJS2ZOybx8RTlIZ5_ho3w8wdIWI"]
    
    static func youtubeURL(method: Method, part: [String], parameters:[String: String]) -> URL {
        var components = URLComponents(string: baseURLString + method.rawValue)!
        var queryItems = [URLQueryItem]()
        let joinedPart = part.joined(separator: ",")
        var item = URLQueryItem(name: "part", value: joinedPart)
        queryItems.append(item)
        for (key, value) in parameters {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        let random = Int(arc4random_uniform(4))
        item = URLQueryItem(name: "key", value: APIKey[random])
        queryItems.append(item)
        components.queryItems = queryItems
        
        return components.url!
    }
    
    static func stuckSubscriberCountForId(_ id: String, completionHandler: @escaping (Result<String>) -> Void ) {
        if let url = URL(string: "https://query.yahooapis.com/v1/public/yql?q=SELECT%20*%20FROM%20html%20where%20url%3D%22https%3A%2F%2Fwww.youtube.com%2Fchannel%2F\(id)%2Fabout%22%20%0AAND%20xpath%3D'%2F%2F*%5B%40class%3D%22about-stats%22%5D%2F%2Fb'&format=json") {
            jsonSerialization(url, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .success(result):
                    if let query = result["query"] as? [String: AnyObject],
                        let results = query["results"] as? [String: AnyObject],
                        let subscribers = results["b"] as? [String],
                        subscribers.count > 0,
                        let string = Int(subscribers[0].replacingOccurrences(of: ",", with: ""))?.stringInDecimal {
                        completionHandler(.success(string))
                    } else {
                        completionHandler(.failure(Error.stuckSubError))
                        print("WrongDataFormat")
                    }
                case let .failure(error):
                    print(error)
                    completionHandler(.failure(Error.stuckSubError))
                }
            })
        }
    }
    
    static func idForName(_ name: String, completionHandler: @escaping (Result<String>) -> Void ){
        if name.characters.count == 24 {
            print("ID already known")
            completionHandler(.success(name))
        } else {
            let url = youtubeURL(method: .Search, part: ["snippet"], parameters: ["q": name, "type": "channel"])
            jsonSerialization(url, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .success(result):
                    if let pageInfo = result["pageInfo"] as? NSDictionary,
                        let totalResults = pageInfo["totalResults"] as? Int , totalResults > 0,
                        let items = result["items"] as? [[String:AnyObject]] , items.count > 0,
                        let snippet = items[0]["snippet"] as? NSDictionary,
                        let id = snippet["channelId"] as? String {
                        completionHandler(.success(id))
                    } else {
                        completionHandler(.failure(Error.idError))
                    }
                case let .failure(error):
                    print(error)
                    completionHandler(.failure(error))
                }
            })
        }
    }
    
    static func jsonSerialization(_ url: URL, completionHandler: @escaping (Result<[String: AnyObject]>) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            do {
                if let myData = data, let result = try JSONSerialization.jsonObject(with: myData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                    completionHandler(.success(result))
                } else {
                    completionHandler(.failure(Error.jsonError))
                }
            } catch {
                completionHandler(.failure(Error.jsonError))
            }
        })
        task.resume()
    }
    static func fetchYoutubeData(forID id: String, parameters: [DataParameters], completionHandler: @escaping (Result<[String: Any]>) -> Void) {
        var subscriberDictionary = [String: Any]()
        var part = ["statistics"]
        if parameters.contains(.photo) {
            part.append("snippet")
        }
        let url = youtubeURL(method: .Channels, part: part, parameters: ["id": id])
        jsonSerialization(url, completionHandler: { jsonResult -> Void in
            switch jsonResult {
            case let .success(result):
                if let items = result["items"] as? [[String: AnyObject]] , items.count > 0 {
                    if let statistics = items[0]["statistics"] as? [String: AnyObject],
                        let subscriberCount = statistics["subscriberCount"] as? String,
                        let liveSubscriberCount = Int(subscriberCount)?.stringInDecimal,
                        let viewCount = statistics["viewCount"] as? String,
                        let views = Int(viewCount)?.stringInDecimal,
                        let videoCount = statistics["videoCount"] as? String,
                        let videos = Int(videoCount)?.stringInDecimal {
                        subscriberDictionary["liveSubscriberCount"] = liveSubscriberCount
                        subscriberDictionary["viewCount"] = views
                        subscriberDictionary["videoCount"] = videos
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
                completionHandler(.success(subscriberDictionary))
            case let .failure(error):
                print(error)
                completionHandler(.failure(error))
            }
        })
    }
    
    public static func parseProfile(forName: String, completionHandler: @escaping (Result<Any>) -> Void) {
        idForName(forName, completionHandler: { idResult -> Void in
            switch idResult {
            case let .success(id):
                parseData(forID: id, parameters: [.data, .photo, .stuckSubscriberCount], completionHandler: { dataResult -> Void in
                    switch dataResult {
                    case let .success(result):
                        completionHandler(.success(result))
                    case let .failure(error):
                        switch error {
                        case Error.jsonError: completionHandler(.failure(error))
                        default: completionHandler(.failure(Error.constructingError))
                        }
                    }
                })
            case let .failure(error):
                switch error {
                case Error.idError: completionHandler(.failure(error))
                default:
                    completionHandler(.failure(Error.constructingError))
                }
            }
        })
    }
    public static func parseData(forID id: String, parameters: [DataParameters], completionHandler: @escaping (Result<[String: Any]>) -> Void) {
        var subscriberDictionary = [String: Any]()
        let group = DispatchGroup()
        if parameters.contains(.data) {
            group.enter()
            fetchYoutubeData(forID: id, parameters: parameters, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .success(result): subscriberDictionary.merge(result)
                case let .failure(error): print(error)
                }
                group.leave()
            })
        }
        if parameters.contains(.stuckSubscriberCount) {
            group.enter()
            stuckSubscriberCountForId(id, completionHandler: { subsResult -> Void in
                switch subsResult {
                case let .success(result): subscriberDictionary["stuckSubscriberCount"] = result
                case let .failure(error): print(error)
                }
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.main) {
            subscriberDictionary["id"] = id
            if subscriberDictionary["stuckSubscriberCount"] == nil && parameters.count == 3{
                if let live = subscriberDictionary["liveSubscriberCount"] as? String {
                    subscriberDictionary["stuckSubscriberCount"] = live
                }
            }
            if parameters.count == 3 && subscriberDictionary.count != 7 {
                completionHandler(.failure(Error.constructingError))
            } else {
                completionHandler(.success(subscriberDictionary))
            }
        }
    }
}
