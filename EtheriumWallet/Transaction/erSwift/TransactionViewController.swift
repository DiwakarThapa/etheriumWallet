//
//  TransactionViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/7/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import Web3
import PromiseKit
import BigInt
import AVFoundation
import QRCodeReader

let web3 = Web3(rpcURL: baseURl.absoluteString)

class TransactionViewController: UIViewController {

    
    @IBOutlet weak var privateField: UITextField!
    @IBOutlet weak var toAddressField: UITextField!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var transactionBtn: UIButton!
    @IBOutlet weak var transactionHashLabel: UILabel!
    
    var privKey:String?
    var transactionHash: String? {
        didSet {
            self.transactionHashLabel.text = transactionHash
        }
    }
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.privateField.text = privKey
         self.transactionBtn.isHidden = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Token", style: .plain, target: self, action: #selector(transferToken))
        // Do any additional setup after loading the view.
    }
    
    @objc private func transferToken() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "TransactionDetailsViewController") as! TransactionDetailsViewController
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func scanAction(_ sender: Any) {
        readerVC.delegate = self
        
        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            self.toAddressField.text = result?.value
        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    @IBAction func transferAction(_ sender: Any) {
        
        if self.privateField.text != "" {
        let amount = Int.init((Double(self.amountField.text ?? "") ?? 0)*1000000000000000000)
        
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + (self.privateField.text ?? ""))
        firstly {
            web3.eth.getTransactionCount(address: privateKey.address, block: .latest)
            }.then { nonce in
                Promise { seal in
                    var tx = try EthereumTransaction(
                        nonce: nonce,
                        gasPrice: EthereumQuantity(quantity: 21.gwei),
                        gasLimit: 21000,
                        to: EthereumAddress(hex: self.toAddressField.text ?? "", eip55: false),
                        value: EthereumQuantity(quantity: BigUInt.init(amount)),
                        chainId: 1
                        )
                    try! tx.sign(with: privateKey)
                    seal.resolve(tx, nil)
                }
            }.then { tx in
                web3.eth.sendRawTransaction(transaction: tx)
            }.done { hash in
         
                self.whisperSuccess(message: "Transaction completed.")
                self.transactionBtn.isHidden = false
                self.transactionHash = hash.hex()
            }.catch { error in
          
                self.whisper(message: error.localizedDescription)
        }
        }else {
            self.whisper(message: "Please unlock your wallet first.")
        }
    }
    
    @IBAction func viewTransactionAction(_ sender: Any) {
        getTransactionReciept()
    
    }
    
    private func getTransactionReciept() {
        firstly {
           web3.eth.getTransactionReceipt(transactionHash: try! EthereumData.string(self.transactionHash ?? ""))
            }.done { response in
                let webVc = WebLinksViewController()
                webVc.url = "https://ropsten.etherscan.io/tx/" + (response?.transactionHash.hex() ?? "")
                webVc.titleString = "Transaction Details"
                self.navigationController?.pushViewController(webVc, animated: true)
            }.catch { (error) in
                self.whisper(message: "Your transaction is currently pending.")
        }
    }
}

extension TransactionViewController: QRCodeReaderViewControllerDelegate {
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
}
