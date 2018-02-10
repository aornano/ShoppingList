//
//  Utils.swift
//  ShoppingList
//
//  Created by Alessandro Ornano on 08/02/2018.
//  Copyright © 2018 Alessandro Ornano. All rights reserved.
//

import Foundation
import UIKit

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- General types and constants
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
typealias APISuccess = (_ result: [String:Any]) -> Void
typealias APIFailure = (_ error: [String:Any]) -> Void

struct Constants {
    static let BASE_URL = "http://apilayer.net/api/"
    static let API_KEY = "ac885639fc13bb7f10201c967ade62cf"
    static let LOADING = "Loading codes.."
    static let RETRIEVING = "Retrieving exchange rates.."
    static let SELECT_YOUR_CURRENCY = "Select your currency:"
    static let NOT_UPDATED_YET = "Not updated yet!"
    static let LAST_UPDATE = "Last update: "
    static let ERROR_TITLE = "Error"
    static let ERROR_RETRIEVING_DATA = "Error while retrieving currencies data, please try later.."
    static let NUM = "num"
    static let PRICE = "price"
    static let CURRENT_CODE = "current code: "
}

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- General useful methods
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
func getCurrentDateFromTimestamp(_ timestamp:TimeInterval)->String {
    let date = Date(timeIntervalSince1970: timestamp)
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
    return formatter.string(from: date)
}
// Crypto values needs more precision : rates like Bitcoin are 0.000115 so change could be 0.00 with 2 decimals
func changeDecimalsForLittleRates( _ value:Double, qty:Int)->Int {
    guard qty == 0 || value >= 0.01 else { return 5 }
    return 2
}

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- API objects
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
struct CurrenciesList: Codable {
    let success: Bool
    let currencies: [String: String]
    enum ListKeys: String, CodingKey{
        case success, currencies
    }
    init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: ListKeys.self)
        success = try container.decode (Bool.self, forKey: .success)
        currencies = try container.decode ([String: String].self, forKey: .currencies)
    }
    func encode (to encoder: Encoder) throws {
        var container = encoder.container (keyedBy: ListKeys.self)
        try container.encode (success, forKey: .success)
        try container.encode (currencies, forKey: .currencies)
    }
}
struct CurrenciesLive: Codable {
    let success: Bool
    let timestamp : Double
    let quotes: [String: Double]
    enum LiveKeys: String, CodingKey{
        case success, timestamp, quotes
    }
    init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: LiveKeys.self)
        success = try container.decode (Bool.self, forKey: .success)
        timestamp = try container.decode (Double.self, forKey: .timestamp)
        quotes = try container.decode ([String: Double].self, forKey: .quotes)
    }
    func encode (to encoder: Encoder) throws {
        var container = encoder.container (keyedBy: LiveKeys.self)
        try container.encode (success, forKey: .success)
        try container.encode (timestamp, forKey: .timestamp)
        try container.encode (quotes, forKey: .quotes)
    }
}

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- URL sessions to call a rest API
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- Abstract call a rest API
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
func callAPI<GenericCodable>(urlString: String, genericCodable:GenericCodable.Type, success successBlock : @escaping APISuccess,
                        failure failureBlock :  @escaping APIFailure) where GenericCodable: Codable {
    guard let url = URL(string: urlString) else { return }
    var request : URLRequest = URLRequest(url: url)
    request.httpMethod = "GET"
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        if error != nil { // HTTP error
            print(error!.localizedDescription)
            failureBlock(["error":error!])
        }
        guard let data = data else { return }
        do { // HTTP success
            let data = try JSONDecoder().decode(genericCodable, from: data)
            successBlock(["data":data])
        } catch let jsonError { //decoding json failed
            print(jsonError)
            failureBlock(["error":jsonError])
        }
    }.resume()
}
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- Cancel all tasks in the URLSession shared instance
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
func cancelTasks(completion:@escaping (Bool) -> ()) {
    let session = URLSession.shared
    session.getTasksWithCompletionHandler { (dataTask, _, _) in
        _ = dataTask.map({ $0.cancel()})
        if dataTask.count == 0 {
            print(" - all remote calling tasks are removed..")
            completion(true)
        } else {
            completion(false)
        }
    }
}
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- call API: list of supported currencies
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
func getCurrenciesList( success successBlock : @escaping APISuccess,
                       failure failureBlock :  @escaping APIFailure) {
    let urlString = Constants.BASE_URL + "list?access_key=" + Constants.API_KEY
    print(" - calling currencylayer API list..")
    print("   ♦ resume or start API LIST url: \(urlString)")
    callAPI(urlString: urlString, genericCodable:CurrenciesList.self, success: { (result) in
        if let currenciesList = result["data"] { // check json success field
            let successField = (currenciesList as! CurrenciesList).success
            successField ? successBlock(result) : failureBlock(["error":"data not available"])
        }
    }) { (failure) in
        failureBlock(failure)
    }
}

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- call API: live to download the latest quotes
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
func getCurrenciesLive( success successBlock : @escaping APISuccess,
                        failure failureBlock :  @escaping APIFailure) {
    let urlString = Constants.BASE_URL + "live?access_key=" + Constants.API_KEY + "&source=USD"
    print(" - calling currencylayer API live..")
    print("   ♣ resume or start API LIVE url: \(urlString)")
    callAPI(urlString: urlString, genericCodable:CurrenciesLive.self, success: { (result) in
        if let currenciesLive = result["data"] { // check json success field
            let successField = (currenciesLive as! CurrenciesLive).success
            successField ? successBlock(result) : failureBlock(["error":"data not available"])
        }
    }) { (failure) in
        failureBlock(failure)
    }
}

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- Extensions
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
extension UIActivityIndicatorView {
    func turnOff() {
        self.isHidden = true
        self.stopAnimating()
    }
}
