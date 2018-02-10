## ShoppingList
>This iOS project can price a simple basket of goods in a number of different currencies.

[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat
)](https://developer.apple.com/swift)
[![Build Status](https://travis-ci.org/Alamofire/Alamofire.svg?branch=master)](https://travis-ci.org/Alamofire/Alamofire)
[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
)](https://developer.apple.com/iphone/index.action)

Available directions:

![](directions.png) 

Demo:

![demo](demo4.gif) 

The goods that can be purchased, which are all priced in US$, are:
- Peas: $ 0,95 per bag
- Eggs: $ 2,10 per dozen
- Milk: $ 1,30 per bottle
- Beans: $ 0,73 per can
The program shall allow the user to add or remove items in a basket. The user can click on a checkout button, which will then display the total price for the basket with the option to display the amount in different currencies.

The list of currencies come from http://jsonrates.com/.

- [Features](#features)
- [Testing](#testing)
- [Requirements](#requirements)
- [Communication](#communication)
- [Installation](#installation)
- [Memory managment](#memory_managment)

## Features

- [x] If you set the property ```.rate``` , the basket calculate automatically the total in the currency rate you have setted.
- [x] If you remove ALL products from your basket you always know the price of each good, in case you decide to not buy a too expensive product for you.
- [x] Network availability is always showed as well as the last currencies update date

Methods to handling goods in a basket :
```
    -  addGood(_ name:String, imageName:String? = nil, amount:Int? = 1, currentPriceForUnity:Double = 0.0, currentCurrency:String? = "USD") 
    - removeGood(_ name:String) 
    - checkGood(_ name:String)->Bool
    - getGood(_ name:String)->Good?
    - calculateQuantity()->Int
    - calculateTotal()->Double
```

## Testing
- [x] The ```XCTestCase``` class ```ShoppingListTests``` contains a list of useful methods to test the basket model and the network API calls

## Requirements

- iOS 10.3+
- Xcode 9.2+
- Swift 4.0+

## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.

## Installation

Download the project and run it.

## Memory managment

The app don't have memory leaks or retain cycles according to the Leaks instrument (Xcode) as showed in this picture:

![](leaks.png) 

The ```deinit``` method inside the ```MainViewController``` is called also when the application terminated because it's the **rootViewController** for the initial ```UINavigationController```

Just only to make this test and verify the correct deallocation of memory during the ```MainViewController``` releasing, I've added a temporary ```UIViewController``` as a **rootViewController** for the initial ```UINavigationController``` with a simple button that push and show the ```MainViewController```. As you can see after the press of the back button to exit from the ```MainViewController```, the ```deinit``` method was called correctly.

![](deinit.gif) 
