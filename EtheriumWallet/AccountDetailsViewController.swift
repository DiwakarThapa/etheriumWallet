//
//  AccountDetailsViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 2/9/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import Geth
import QRCode
import Web3
import PromiseKit
import BigInt
import Floaty
import QRCodeReader

struct Constants {
//    static let liveUrl = "https://api.myetherapi.com/eth"
//    static let testUrl = "https://api.myetherapi.com/rop"
//    static let wallet = "WalletA"
    static let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
}


class AccountDetailsViewController: UIViewController {

    @IBOutlet weak var addressLabel: UITextView!
    @IBOutlet weak var qrView: UIImageView!
    @IBOutlet weak var transactionBtn: UIButton!
    var account: iGethAccount?
    var ks:iGethAccountManager?
    var privKey: String?
    var currentBalance: String?
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transactionBtn.layer.cornerRadius = transactionBtn.frame.height/2
        let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        ks = iGethNewAccountManager(datadir + "/etherKeyStore", iGethLightScryptN, iGethLightScryptP)
        self.title = "Account Details"
    
        self.addressLabel.text = account?.getAddress().getHex()
        let qr = QRCode(account?.getAddress().getHex() ?? "")
        self.qrView.image = qr?.image
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "lock"), style: .done, target: self, action: #selector(getPrivateKey))
        setupFloaty()
    }
    
    func setupFloaty() {
        let floaty = Floaty()
        floaty.size = 60
        floaty.plusColor = UIColor.white
        floaty.buttonColor = UIColor.init(hex: "#267A16")
        floaty.itemSize = 50
        floaty.addItem(icon: UIImage.init(named: "transaction")) { (item) in
            let popUp = QuickTransactionPopUp()
            popUp.setup()
            popUp.didFinishAdding = { data in
                let dataStr = "Amount \(data.amount ?? 0) \(data.currency?.tokenName ?? "") \(data.currency?.contractAddress ?? "") Address \(self.account?.getAddress().getHex() ?? "")"
                let data = Data(dataStr.utf8)
                let vc = UIStoryboard.init(name: "QuickTransaction", bundle: nil).instantiateViewController(withIdentifier: "QuickTransactionViewController") as! QuickTransactionViewController
                vc.data = data.hexEncodedString()
                self.navigationController?.pushViewController(vc, animated: true)
            }
            popUp.present()
        }
        floaty.addItem(title: "PAY NOW") { (item) in
            self.readerVC.delegate = self
            
            // Or by using the closure pattern
            self.readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                if self.privKey == nil {
                    self.whisper(message: "Please unlock your private key first.")
                }else {
                let vc = UIStoryboard.init(name: "PayNow", bundle: nil).instantiateViewController(withIdentifier: "PayNowViewController") as! PayNowViewController
                vc.privateKey = self.privKey
                vc.hex = result?.value
                self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            // Presents the readerVC as modal form sheet
            self.readerVC.modalPresentationStyle = .formSheet
            self.present(self.readerVC, animated: true, completion: nil)
        }
        self.view.addSubview(floaty)
    }
    
    func getBalance() {
        self.showProgressHudWith(title: "Calculating Balance...")
        firstly{
            web3.eth.blockNumber()
            }.then { quantity in
                web3.eth.getBalance(address: try! EthereumAddress(hex: self.addressLabel.text, eip55: false), block: EthereumQuantityTag.block(quantity.quantity))
            }.done { (quantity) in
                self.currentBalance = "\(Double(quantity.quantity)/Double(BigInt(1).eth)) .ETH"
                let popup = AccountDetailsPopUp()
                popup.accountAddress = self.addressLabel.text
                popup.contractAddress = baseContractAddress
                popup.balance = self.currentBalance
                popup.getBalance()
                self.hideProgressHud()
                popup.present()
            }.catch { (error) in
                print(error)
        }
    }
    
    @objc private func getPrivateKey() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CheckPinViewController") as! CheckPinViewController
        vc.checkPin = {code in
            
            // GETTING JSON DATA
            do {
            let data = try self.ks?.exportKey(self.account ?? iGethAccount(), passphrase: code, newPassphrase: code)
                let json = String.init(data: data!, encoding: .utf8)!
                let dict: [String:Any] = ["jsonData" : json , "publicAddress": self.account?.getAddress().getHex() ?? ""]
                UserDefaults.standard.setValue(dict, forKey: Constants.wallet)
                
                // GENERATING PRIVATE KEY
                let vc = UIStoryboard(name: "KeyGenerator", bundle: nil).instantiateViewController(withIdentifier: "KeyGeneratorViewController") as! KeyGeneratorViewController
                vc.password = code
                vc.didRecievePrivateKey = { key in
                    self.privKey = key
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }catch {
                self.whisper(message: "Incorrect Pin" )
                self.addressLabel.text = self.account?.getAddress().getHex()
            }
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func getAccountDetailsAction(_ sender: Any) {
        self.getBalance()
    }
    
    @IBAction func transactionAction(_ sender: Any) {
        if self.privKey == nil {
            self.whisper(message: "Please unlock our private key first.")
        }else {
        let vc = UIStoryboard(name: "Transaction", bundle: nil).instantiateViewController(withIdentifier: "TransactionViewController") as! TransactionViewController
        vc.privKey = self.privKey
        self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension AccountDetailsViewController: QRCodeReaderViewControllerDelegate {
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
}
