//
//  CheckoutViewController.swift
//  ShoppingList
//
//  Created by Alessandro Ornano on 08/02/2018.
//  Copyright © 2018 Alessandro Ornano. All rights reserved.
//

import Foundation
import UIKit

class CheckoutViewController: UIViewController {
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- IBOutlets
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    @IBOutlet weak var reportLabel: UILabel!
    @IBOutlet weak var greetingsLabel: UILabel!
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Other vars
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    var finalQty:Int = 0
    var finalTotal:Double = 0.0
    var selectedCurrency:String = "USD"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("---\n❊ \(type(of: self))\n---")
        self.title = "Shipping Report"
        let decimals = changeDecimalsForLittleRates(finalTotal,qty: finalQty)
        self.reportLabel.text = "You've selected \(finalQty) products for a total of \(selectedCurrency) \(String(format: "%.\(decimals)f", finalTotal ))"
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK: End methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        print("- \(type(of: self)) deinit")
    }
}
