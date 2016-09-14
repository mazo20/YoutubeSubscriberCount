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
    case success(AnyObject)
    case failure(Error)
}
public enum Error {
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
    
    static func stuckSubscriberCountForId(_ id: String, completionHandler: @escaping (Result) -> Void ) {
        if let url = URL(string: "https://query.yahooapis.com/v1/public/yql?q=SELECT%20*%20FROM%20html%20where%20url%3D%22https%3A%2F%2Fwww.youtube.com%2Fchannel%2F\(id)%2Fabout%22%20%0AAND%20xpath%3D'%2F%2F*%5B%40class%3D%22about-stats%22%5D%2F%2Fb'&format=json") {
            jsonSerialization(url, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .success(result):
                    if let query = result["query"] as? [String: AnyObject],
                        let results = query["results"] as? [String: AnyObject],
                        let subscribers = results["b"] as? [String] , subscribers.count > 0 {
                        var numberText = subscribers[0]
                        numberText = numberText.replacingOccurrences(of: ",", with: "")
                        if let number = Int(numberText) {
                            let numberFormatter = NumberFormatter()
                            numberFormatter.numberStyle = NumberFormatter.Style.decimal
                            let s = numberFormatter.string(from: NSNumber(integerLiteral: number))
                            completionHandler(.success(s! as AnyObject))
                        }
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
    
    static func idForName(_ name: String, completionHandler: @escaping (Result) -> Void ){
        if name.characters.count == 24 {
            print("ID already known")
            completionHandler(.success(name as AnyObject))
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
                        completionHandler(.success(id as AnyObject))
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
    
    static func jsonSerialization(_ url: URL, completionHandler: @escaping (Result) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            do {
                if let myData = data, let result = try JSONSerialization.jsonObject(with: myData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                    completionHandler(.success(result as AnyObject))
                } else {
                    completionHandler(.failure(Error.jsonError))
                }
            } catch {
                completionHandler(.failure(Error.jsonError))
            }
        })
        task.resume()
    }
    static func fetchYoutubeData(forID id: String, parameters: [DataParameters], completionHandler: @escaping (Result) -> Void) {
        var subscriberDictionary = [String: AnyObject]()
        var part = ["statistics"]
        if parameters.contains(.photo) {
            part.append("snippet")
        }
        let url = youtubeURL(method: .Channels, part: part, parameters: ["id": id])
        jsonSerialization(url, completionHandler: { jsonResult -> Void in
            switch jsonResult {
            case let .success(result):
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                if let items = result["items"] as? [[String: AnyObject]] , items.count > 0 {
                    if let statistics = items[0]["statistics"] as? [String: AnyObject],
                        let subscriberCount = statistics["subscriberCount"] as? String,
                        let subscriberNumber = Int(subscriberCount),
                        let finalSubscriber = numberFormatter.string(from: NSNumber(integerLiteral: subscriberNumber)),
                        let viewCount = statistics["viewCount"] as? String,
                        let viewNumber = Int(viewCount),
                        let finalView = numberFormatter.string(from: NSNumber(integerLiteral: viewNumber)),
                        let videoCount = statistics["videoCount"] as? String,
                        let videoNumber = Int(videoCount),
                        let finalVideo = numberFormatter.string(from: NSNumber(integerLiteral: videoNumber)) {
                            subscriberDictionary["liveSubscriberCount"] = finalSubscriber as AnyObject?
                            subscriberDictionary["viewCount"] = finalView as AnyObject?
                            subscriberDictionary["videoCount"] = finalVideo as AnyObject?
                    }
                    if let snippet = items[0]["snippet"] as? NSDictionary,
                        let thumbnails = snippet["thumbnails"] as? NSDictionary,
                        let image = thumbnails["medium"] as? NSDictionary,
                        let urlString = image["url"] as? String,
                        let title = snippet["title"] as? String {
                        let url = URL(string: urlString)
                        let imageData = try? Data(contentsOf: url!)
                        subscriberDictionary["image"] = UIImage(data: imageData!)
                        subscriberDictionary["channelName"] = title as AnyObject?
                    }
                }
                completionHandler(.success(subscriberDictionary as AnyObject))
            case let .failure(error):
                print(error)
                completionHandler(.failure(error))
            }
        })
    }
    
    public static func parseAllData(_ forName: String, completionHandler: @escaping (Result) -> Void) {
        idForName(forName, completionHandler: { idResult -> Void in
            switch idResult {
            case let .success(result):
                let id = result as! String
                parseData(forID: id, parameters: [.data, .photo, .stuckSubscriberCount], completionHandler: { dataResult -> Void in
                    switch dataResult {
                    case let .success(result):
                        completionHandler(.success(result as! [String: AnyObject] as AnyObject))
                    case let .failure(error):
                        print(error)
                        switch error {
                            case Error.jsonError:
                            completionHandler(.failure(error))
                            default:
                            completionHandler(.failure(Error.constructingError))
                        }
                    }
                })
            case let .failure(error):
                print(error)
                switch error {
                case Error.idError:
                    completionHandler(.failure(error))
                default:
                    completionHandler(.failure(Error.constructingError))
                }
            }
        })
    }
    public static func parseData(forID id: String, parameters: [DataParameters], completionHandler: @escaping (Result) -> Void) {
        var subscriberDictionary = [String: AnyObject]()
        let group = DispatchGroup()
        if parameters.contains(.data) {
            group.enter()
            fetchYoutubeData(forID: id, parameters: parameters, completionHandler: { dataResult -> Void in
                switch dataResult {
                case let .success(result):
                    subscriberDictionary.merge(result as! [String: AnyObject])
                    group.leave()
                case let .failure(error):
                    print(error)
                    group.leave()
                }
            })
        }
        if parameters.contains(.stuckSubscriberCount) {
            group.enter()
            stuckSubscriberCountForId(id, completionHandler: { subsResult -> Void in
                switch subsResult {
                case let .success(result):
                    subscriberDictionary["stuckSubscriberCount"] = result as! String as AnyObject?
                    group.leave()
                case let .failure(error):
                    print(error)
                    group.leave()
                }
            })
        }
        group.notify(queue: DispatchQueue.main) {
            subscriberDictionary["id"] = id as AnyObject?
            if subscriberDictionary["stuckSubscriberCount"] == nil && parameters.count == 3{
                if let live = subscriberDictionary["liveSubscriberCount"] as? String {
                    subscriberDictionary["stuckSubscriberCount"] = live as AnyObject?
                }
            }
            if parameters.count == 3 {
                if subscriberDictionary.count == 7 {
                    completionHandler(.success(subscriberDictionary as AnyObject))
                } else {
                    completionHandler(.failure(Error.constructingError))
                }
            } else {
                completionHandler(.success(subscriberDictionary as AnyObject))
            }
            
        }
    }
}
