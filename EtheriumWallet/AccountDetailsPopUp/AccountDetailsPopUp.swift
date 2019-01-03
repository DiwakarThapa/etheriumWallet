//
//  AccountDetailsPopUp.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/14/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import web3swift
import BigInt
import MBProgressHUD

class AccountDetailsPopUp: UIView {


    @IBOutlet weak var dialogView: UIView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var tokenBalanceLabel: UILabel!
    
    var accountAddress: String?
    var contractAddress:String?
    var balance: String?
    init() {
        super.init(frame: UIScreen.main.bounds)
        loadFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    private func loadFromNib() {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "AccountDetailsPopUp", bundle: bundle)
        if  let popup = nib.instantiate(withOwner: self, options: nil).first as? UIView {
            popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            popup.frame = self.bounds
            addSubview(popup)
        }
        
    }
    
    let json = """
    [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"},{"name":"_extraData","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"type":"function"},{"inputs":[{"name":"_initialAmount","type":"uint256"},{"name":"_tokenName","type":"string"},{"name":"_decimalUnits","type":"uint8"},{"name":"_tokenSymbol","type":"string"}],"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}]
"""
    
    func getBalance() {
        self.balanceLabel.text = self.balance
        let keystoreManager = KeystoreManager.managerForPath(datadir + "/etherKeyStore")
        let web3Main = Web3.new(baseURl)!
        let coldWalletAddress = EthereumAddress(accountAddress ?? "")
        let constractAddress = EthereumAddress(contractAddress ?? "")
        let gasPriceResult = web3Main.eth.getGasPrice()
        guard case .success(let gasPrice) = gasPriceResult else {return}
        var options = Web3Options.defaultOptions()
        options.gasPrice = gasPrice
        options.from = EthereumAddress(accountAddress ?? "")
        let parameters = [] as [AnyObject]

        web3Main.addKeystoreManager(keystoreManager)
        let contract = web3Main.contract(json, at: constractAddress, abiVersion: 2)!
        let intermediate = contract.method("name", parameters:parameters,  options: options)
        guard let tokenNameRes = intermediate?.call(options: options) else {return}
        guard case .success(let result) = tokenNameRes else {return}
        self.tokenNameLabel.text = (result["0"] as! String)

        guard let bkxBalanceResult = contract.method("balanceOf", parameters: [coldWalletAddress] as [AnyObject], options: options)?.call(options: nil) else {return}
        guard case .success(let bkxBalance) = bkxBalanceResult, let bal = bkxBalance["0"] as? BigUInt else {return}
        self.tokenBalanceLabel.text = String(bal/BigUInt(1000))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dialogView.layer.cornerRadius = 5.0
    }
    
    // IBActions
    @IBAction func dissmissBtn(_ sender: Any) {
        dissmiss()
    }
    
}



extension AccountDetailsPopUp {
    
    func present() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dialogView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        //self.alpha = 0
        appDelegate?.window?.addSubview(self)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseOut, animations: {() -> Void in
            
            self.dialogView.transform = CGAffineTransform.identity
            //self.alpha = 1
            
        }, completion: { _ in
            
        })
    }
    
    func dissmiss() {
        self.alpha = 1
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseOut, animations: {() -> Void in
            self.dialogView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0
            
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
struct Associate {
    static var hud: UInt8 = 0
    static var empty: UInt8 = 0
}

extension UIViewController{
    private func setProgressHud() -> MBProgressHUD {
        
        let progressHud:  MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.tintColor = UIColor.darkGray
        progressHud.removeFromSuperViewOnHide = true
        objc_setAssociatedObject(self, &Associate.hud, progressHud, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return progressHud
    }
    
    var progressHud: MBProgressHUD {
        if let progressHud = objc_getAssociatedObject(self, &Associate.hud) as? MBProgressHUD {
            progressHud.isUserInteractionEnabled = true
            return progressHud
        }
        return setProgressHud()
    }
    
    var progressHudIsShowing: Bool {
        return self.progressHud.isHidden
    }
    
    func showProgressHud() {
        self.progressHud.show(animated: false)
    }
    
    func showProgressHudWith(title: String) {
        self.progressHud.label.text = title
        self.progressHud.show(animated: false)
    }
    
    func hideProgressHud() {
        self.progressHud.label.text = ""
        self.progressHud.completionBlock = {
            objc_setAssociatedObject(self, &Associate.hud, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        self.progressHud.hide(animated: false)
    }
    
}
