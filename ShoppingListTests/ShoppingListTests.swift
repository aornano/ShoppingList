//
//  ShoppingListTests.swift
//  ShoppingListTests
//
//  Created by Alessandro Ornano on 10/02/2018.
//  Copyright © 2018 Alessandro Ornano. All rights reserved.
//

import UIKit
import XCTest
@testable import ShoppingList
class ShoppingListTests: XCTestCase {
    var mainVCUnderTest: MainViewController!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        mainVCUnderTest = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        if(mainVCUnderTest != nil) {
            mainVCUnderTest.loadView()
            mainVCUnderTest.viewDidLoad()
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mainVCUnderTest = nil
        super.tearDown()
    }
    
    func testMainVC_canBeInstantiated() {
        XCTAssertNotNil(mainVCUnderTest)
    }
    
    func testMainVC_basket() {
        XCTAssertNotNil(mainVCUnderTest.basket)
    }
    
    func testMainVC_addGood() {
        mainVCUnderTest.basket.addGood("Bread")
        _ = mainVCUnderTest.basket.checkGood("Bread")
        XCTAssertNotNil(mainVCUnderTest.basket.getGood("Bread"))
        if let bread = mainVCUnderTest.basket.getGood("Bread") {
            XCTAssertEqual(bread.currentPrice, 0.0, "Price not defined for a default good should be 0.0")
        }
        
    }
    func testMainVC_removeGood(_ name:String = "Bread") {
        mainVCUnderTest.basket.removeGood(name)
        XCTAssertNil(mainVCUnderTest.basket.getGood(name))
    }
    
    func testMainVC_milkConversionExample() {
        XCTAssertEqual(mainVCUnderTest.basket.quantity, 4, "Basket default quantity should be 4 : 1 Peas, 1 Eggs, 1 Milk and 1 Beans")
        if let _ = mainVCUnderTest.basket.getGood("Milk") { // Milk exist
            // Let's start to remove the other three elements
            testMainVC_removeGood("Peas")
            testMainVC_removeGood("Eggs")
            testMainVC_removeGood("Beans")
            XCTAssertEqual(mainVCUnderTest.basket.quantity, 1, "After removing Peas, Eggs and Beans we should have only Milk")
            XCTAssertEqual(mainVCUnderTest.basket.total, 1.30, "Total for 1 Milk bottle should be 1.30")
            mainVCUnderTest.basket.currentRate = 1.1
            mainVCUnderTest.basket.currentCurrency = "EUR"
            XCTAssertEqual(mainVCUnderTest.basket.total, 1.43, accuracy:  0.000000001, "Total for 1 Milk bottle after EUR conversion to 1.1 should be 1.43")
        }
    }
    
    // MARK:- Network tests
    
    func testMainVC_checkReachability() {
        mainVCUnderTest.checkReachability()
    }
    
    func testCallAPIlayer_ListCompletes() {
        let url = URL(string: "http://apilayer.net/api/list?access_key=ac885639fc13bb7f10201c967ade62cf")
        let promise = expectation(description: "Completion handler invoked")
        var statusCode: Int?
        var responseError: Error?
        URLSession.shared.dataTask(with: url!) { data, response, error in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
        }
        .resume()
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(responseError)
        XCTAssertEqual(statusCode, 200)
    }
    func testCallAPIlayer_LiveCompletes() {
        let url = URL(string: "http://apilayer.net/api/live?access_key=ac885639fc13bb7f10201c967ade62cf&source=USD")
        let promise = expectation(description: "Completion handler invoked")
        var statusCode: Int?
        var responseError: Error?
        URLSession.shared.dataTask(with: url!) { data, response, error in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
            }
            .resume()
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(responseError)
        XCTAssertEqual(statusCode, 200)
    }
    
    func testPerformanceExample() {
        let timestamp: TimeInterval = 1518251346
        self.measure {
            _ = getCurrentDateFromTimestamp(timestamp)
        }
    }
    
}
