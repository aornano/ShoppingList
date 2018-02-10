//
//  MainViewController.swift
//  ShoppingList
//
//  Created by Alessandro Ornano on 07/02/2018.
//  Copyright © 2018 Alessandro Ornano. All rights reserved.
//

import UIKit

// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- Single good object
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
struct Good {
    var name: String
    var imageName: String?
    var currentPriceForUnity: Double = 0.0
    var currentPrice: Double = 0.0
    var amount: Int? {
        didSet {
            currentPrice = self.calculatePrice()
        }
    }
    var currentCurrency:String?
    init(name: String, imageName:String? = nil, amount:Int? = 1 ,currentPriceForUnity:Double = 0.0, currentCurrency:String? = "USD") {
        self.name = name
        self.amount = amount
        self.currentPriceForUnity = currentPriceForUnity
        self.currentCurrency = currentCurrency
        self.currentPrice = calculatePrice()
        self.imageName = imageName
    }
    func calculatePrice()->Double {
        if !currentPriceForUnity.isEqual(to: 0.0) {
            guard let amount = amount else { return 0.0 }
            return self.currentPriceForUnity * Double(amount)
        }
        return self.currentPrice
    }
}
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- Basket object
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
struct Basket {
    var goods = [Good]() // empty
    var quantity: Int {
        get { return self.calculateQuantity() }
        set { quantity = newValue }
    }
    var total: Double {
        get { return self.calculateTotal() }
        set { total = newValue }
    }
    var currentCurrency:String = "USD"
    var currentRate: Double?
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK: Generic goods methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    mutating func addGood(_ name:String, imageName:String? = nil, amount:Int? = 1, currentPriceForUnity:Double = 0.0, currentCurrency:String? = "USD") {
        self.goods.append( Good.init(name: name, imageName: imageName, amount:amount, currentPriceForUnity:currentPriceForUnity, currentCurrency:currentCurrency) )
    }
    mutating func removeGood(_ name:String) {
        self.goods = self.goods.filter { $0.name != name }
    }
    func checkGood(_ name:String)->Bool {
        return self.goods.contains(where: { $0.name == name })
    }
    func getGood(_ name:String)->Good? {
        return self.goods.filter { $0.name == name }.first
    }
    func calculateQuantity()->Int {
        return goods.map{ $0.amount ?? 0 }.reduce(0, +)
    }
    func calculateTotal()->Double {
        if let r = currentRate {
            return goods.map{ $0.currentPrice }.reduce(0, +)*r
        } else {
            return goods.map{ $0.currentPrice }.reduce(0, +)
        }
    }
}
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
//MARK:- MainViewController class
// #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- IBOutlets
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalBtn: UIButton!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var currencyPickerView: UIPickerView!
    @IBOutlet weak var netNotificationLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentCodeLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Other vars
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    var reachability: Reachability? = Reachability(hostName: "www.apple.com")
    var isLastReachable:Bool = false
    var refreshControl:UIRefreshControl!
    let boxList = ["Peas","Eggs","Milk","Beans"]
    let prices = [0.95, 2.10, 1.30, 0.73]
    var basket = Basket() // table data source
    var currencyCodes = ["USD"] // picker data source field 0
    var currencyNames = ["United States Dollar"] // picker data source field 1
    var quotes: CurrenciesLive?
    
    var isShowedHeader: Bool = true {
        didSet {
            guard let table = self.tableView else { return }
            table.beginUpdates()
            table.endUpdates()
        }
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- viewDidLoad
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    override func viewDidLoad() {
        super.viewDidLoad()
        print("---\n❊ \(type(of: self))\n---")
        self.title = "ShoppingList"
        // reading default values
        defaultValues()
        
        // Table
        self.tableView.dataSource = self
        self.tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        tableView.decelerationRate = UIScrollViewDecelerationRateFast
        tableView.register(UINib(nibName: "GoodPadCell", bundle: nil), forCellReuseIdentifier: "GoodPadCell")
        tableView.register(UINib(nibName: "ReachabilityView", bundle: nil), forHeaderFooterViewReuseIdentifier: "ReachabilityView")
        tableView.tableFooterView = UIView()
        
        // Pull to refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "pull to refresh..")
        self.refreshControl.addTarget(self, action: #selector(self.pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Picker
        currencyPickerView.delegate = self
        currencyPickerView.dataSource = self
        
        // Total button
        totalBtn.backgroundColor = .clear
        totalBtn.layer.cornerRadius = 5
        totalBtn.layer.borderWidth = 1
        totalBtn.layer.borderColor = UIColor.blue.cgColor
        totalBtn.clipsToBounds = true
        totalBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // net Notification Label
        self.netNotificationLabel.text = Constants.SELECT_YOUR_CURRENCY
        
        // last update label
        self.lastUpdateLabel.text = Constants.NOT_UPDATED_YET
        
        // current code label
        self.currentCodeLabel.text = Constants.CURRENT_CODE+"USD"
        
        // activity indicator
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
        
        // Reachability observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityDidChange(notification:)), name: Notification.Name("ReachabilityDidChangeNotification"), object: nil)
        // did become active observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive(notification:)),name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        _ = reachability?.startNotifier()
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Refresh data: this method is called when view appear to show and update local and remote info
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func refreshData() {
        self.tableView.reloadData()
        showResults()
        guard let reach = reachability else { return }
        reach.isReachable ? getRemoteCurrencies() : print("")
    }
    
    @objc func pullToRefresh(sender:Any){
        refreshData()
        self.refreshControl.endRefreshing()
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Network calls methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func getLiveAPI(completion:@escaping (Bool) -> ()) {
        self.netNotificationLabel.text = Constants.RETRIEVING
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        getCurrenciesLive(success: {[weak self](result) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.netNotificationLabel.text = Constants.SELECT_YOUR_CURRENCY
                self.activityIndicator.turnOff()
                let q = result["data"] as! CurrenciesLive
                self.quotes = q
                self.lastUpdateLabel.text = Constants.LAST_UPDATE + getCurrentDateFromTimestamp(q.timestamp)
                completion(true)
            }
        }) {[weak self] (failure) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.netNotificationLabel.text = Constants.SELECT_YOUR_CURRENCY
                self.activityIndicator.turnOff()
                let alert = UIAlertController(title: Constants.ERROR_TITLE, message: Constants.ERROR_RETRIEVING_DATA, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                completion(false)
            }
        }
    }
    func getListAPI(completion:@escaping (Bool) -> ()) {
        self.netNotificationLabel.text = Constants.LOADING
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        getCurrenciesList(success: {[weak self](result) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.netNotificationLabel.text = Constants.SELECT_YOUR_CURRENCY
                self.activityIndicator.turnOff()
                let currenciesList = result["data"] as! CurrenciesList
                self.currencyCodes = Array(currenciesList.currencies.keys)
                self.currencyNames = Array(currenciesList.currencies.values)
                self.currencyPickerView.reloadAllComponents()
                completion(true)
            }
        }) {[weak self] (failure) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.netNotificationLabel.text = Constants.SELECT_YOUR_CURRENCY
                self.activityIndicator.turnOff()
                let alert = UIAlertController(title: Constants.ERROR_TITLE, message: Constants.ERROR_RETRIEVING_DATA, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                completion(false)
            }
        }
    }
    
    func getRemoteCurrencies() {
        getListAPI() {[weak self] success in
            guard let `self` = self else { return }
            if success {
                self.getLiveAPI() { _ in }
            }
        }
        
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Refresh various layout elements to show informations related to the datasource
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func showResults() {
        self.quantityLabel.text = "QTY: \(self.basket.quantity)"
        let decimals = changeDecimalsForLittleRates(self.basket.total,qty: self.basket.quantity)
        let totalTitleBtn = "TOT=  \(self.basket.currentCurrency) \(String(format: "%.\(decimals)f",self.basket.total))"
        self.totalBtn.setTitle(totalTitleBtn, for: UIControlState.normal)
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Set default values for goods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func defaultValues() {
        self.basket.goods = boxList.enumerated().map {(arg) -> Good in
            let (index, name) = arg
            return Good.init(name: name, currentPriceForUnity: prices[index])
        }
    }

    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Table view methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.basket.goods.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ReachabilityView") as! ReachabilityView
        return header
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isShowedHeader {
            return 44.0
        } else {
            return 0.0
        }
    }
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if basket.goods.count > 0 {
            let cellIdentifier = "GoodPadCell"
            var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? GoodPadCell!
            if cell == nil {
                cell = GoodPadCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
            }
            cell = makeGoodPadCell( indexPath: indexPath, cell: cell!)
            return cell!
        } else {
            self.tableView.separatorColor = .clear
            return UITableViewCell()
        }
    }

    func makeGoodPadCell(indexPath: IndexPath, cell: GoodPadCell) -> GoodPadCell {
        let row = indexPath.row
        cell.goodImageView.image = UIImage.init(named: self.basket.goods[row].name)
        cell.amountLabel.text = "\(Constants.NUM): \(self.basket.goods[row].amount ?? 0)"
        cell.goodNameLabel.text = self.basket.goods[row].name
        let showThisPrice = self.basket.goods[row].amount == 0 ? self.basket.goods[row].currentPriceForUnity : self.basket.goods[row].currentPrice
        cell.priceLabel.text = "\(Constants.PRICE): $\(String(format: "%.2f", showThisPrice ))"
        // configure the stepper
        cell.priceStepper.value = Double(self.basket.goods[row].amount ?? 0)
        cell.priceStepper.addTarget(self, action: #selector(self.stepperValueDidChanged), for: .valueChanged)
        cell.priceStepper.minimumValue = 0
        cell.priceStepper.tag = row
        cell.priceStepper.maximumValue = 100
        cell.priceStepper.stepValue = 1
        cell.layoutIfNeeded()
        return cell
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- UIStepper actions and methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    @objc func stepperValueDidChanged(sender: AnyObject) {
        let stepper = sender as! UIStepper
        let row = stepper.tag
        self.basket.goods[row].amount = Int(stepper.value)
        let indexPath = IndexPath.init(row: row, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! GoodPadCell
        cell.amountLabel.text = "\(Constants.NUM): \(String(describing: self.basket.goods[row].amount!))"
        let showThisPrice = self.basket.goods[row].amount == 0 ? self.basket.goods[row].currentPriceForUnity : self.basket.goods[row].currentPrice
        cell.priceLabel.text = "\(Constants.PRICE): $\(String(format: "%.2f", showThisPrice ))"
        showResults()
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- UIPickerViewDataSource methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencyCodes.count
    }
    //MARK: UIPickerViewDelegates methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencyCodes[row]+" - "+currencyNames[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let currencyCodeSelected = currencyCodes[pickerView.selectedRow(inComponent: 0)]
        _ = currencyNames[pickerView.selectedRow(inComponent: 0)]
        self.currentCodeLabel.text = Constants.CURRENT_CODE+currencyCodeSelected
        if let q = self.quotes {
            self.basket.currentCurrency = currencyCodeSelected
            let keyRate = "USD"+currencyCodeSelected
            if let rate = q.quotes[keyRate] {
                self.basket.currentRate = rate
            }
            self.showResults()
        }
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.text = currencyCodes[row]+" - "+currencyNames[row]
        return titleLabel
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Total button action tap
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    @IBAction func totalBtnTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "CheckoutViewController")
        if let nav = self.navigationController {
            let checkController = controller as! CheckoutViewController
            checkController.finalQty = self.basket.quantity
            checkController.finalTotal = self.basket.total
            checkController.selectedCurrency = self.basket.currentCurrency
            let transition:CATransition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionPush
            transition.subtype = kCATransitionFromTop
            nav.view.layer.add(transition, forKey: kCATransition)
            nav.pushViewController(checkController, animated: false)
        }
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- Reachability observer notification and methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func checkReachability() {
        guard let reach = reachability else { return }
        isShowedHeader = reach.isReachable ? false : true
        print(" - now internet is \(!isShowedHeader)")
        if isLastReachable != reach.isReachable { refreshData() }
        isLastReachable = reach.isReachable
    }
    @objc func reachabilityDidChange(notification: Notification) {
        checkReachability()
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK: - Other observers
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("\n - applicationDidBecomeActive\n")
        self.refreshData()
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- End methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        print("- \(type(of: self)) deinit")
        NotificationCenter.default.removeObserver(self)
        cancelTasks(){ _ in }
        reachability?.stopNotifier()
    }
}


