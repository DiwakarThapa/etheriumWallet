//
//  TransactionDetailsViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/9/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import Web3
import PromiseKit
import BigInt
import AVFoundation
import QRCodeReader
import DropDown

class TransactionDetailsViewController: UIViewController {

    @IBOutlet weak var contractAddressField: UITextField!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var toAddressField: UITextField!
    @IBOutlet weak var transactionBtn: UIButton!
    @IBOutlet weak var transactionHashLabel: UILabel!

    
    var transactionHash: String? {
        didSet {
            self.transactionHashLabel.text = transactionHash
        }
    }
    
    var tokens: [CurrencyModel]? {
        didSet {
            if let tokensArray = tokens {
                dropdown.dataSource = tokensArray.compactMap{$0.tokenName}
                dropdown.reloadAllComponents()
            }
        }
    }
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
        
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    var selectedToken: CurrencyModel?
    let dropdown = DropDown()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transactionBtn.isHidden = true
        getTokensData()
        self.dropdown.anchorView = contractAddressField
        dropdown.direction = .bottom
        dropdown.selectionAction = { (index, item) in
            self.contractAddressField.text = item
            self.selectedToken = self.tokens?[index]
        }
        dropdown.dismissMode = .automatic
        self.contractAddressField.addTarget(self, action: #selector(tokenDropDown), for: .allTouchEvents)
    }
    
    @objc private func tokenDropDown() {
        dropdown.show()
    }
    
    var priceHex:String = ""
    var toHex = ""
    
    @IBAction func scanQRAction(_ sender: Any) {
        readerVC.delegate = self
        
        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            self.toAddressField.text = result?.value
        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    private func getTokensData() {
        let tokens = realm.objects(CurrencyModel.self)
        self.tokens = Array(tokens)
    }
    
    @IBAction func setupData() {

        let transfer = "0xa9059cbb"
        let n = (Int(Double(self.amountField.text ?? "") ?? 0)*1000)
        let hexString = String(format:"%2X", n)

        for _ in 0 ..< 64 - (hexString.count) {
            priceHex.append("0")
        }
        let price = priceHex + hexString
        var to = self.toAddressField.text ?? ""
        if to.contains("0x") {
            to.remove(at: to.startIndex)
            to.remove(at: to.startIndex)
        }
        
        for _ in 0 ..< 64 - to.count {
            toHex.append("0")
        }
        let toAddress = toHex + to
        let dataHex = transfer + toAddress + price
        let contractData = Data.init(hex: dataHex)
        
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0xa7e693c80189382a22bc554e89e666f8c747163c4ddc44f7a9d0f6d5e3095388")
        firstly {
            web3.eth.getTransactionCount(address: privateKey.address, block: .latest)
            }.then { nonce in
                Promise { seal in
                    var tx = try EthereumTransaction(
                        nonce: nonce,
                        gasPrice: EthereumQuantity(quantity: 21.gwei),
                        gasLimit: 60000,
                        to: EthereumAddress(hex: self.selectedToken?.contractAddress ?? "", eip55: false),
                        value: EthereumQuantity(quantity: BigUInt.init(0)),
                        data: EthereumData.init(bytes: contractData.bytes),
                        chainId: 1
                    )
                    try! tx.sign(with: privateKey)
                    seal.resolve(tx, nil)
                }
            }.then { tx in
                web3.eth.sendRawTransaction(transaction: tx)
            }.done { hash in
             
                self.transactionHash =  hash.hex()
                self.transactionBtn.isHidden = false
                self.whisperSuccess(message: "Transaction completed.")
                
            }.catch { error in
              
                self.whisper(message: error.localizedDescription)
        }
        
    }
    
    @IBAction func viewTransactionAction(_ sender: Any) {
        firstly {
            web3.eth.getTransactionReceipt(transactionHash: try! EthereumData.string(self.transactionHash ?? ""))
            }.done { response in
                let webVc = WebLinksViewController()
                webVc.url = "https://etherscan.io/tx/" + (response?.transactionHash.hex() ?? "")
                webVc.titleString = "Transaction Details"
                self.navigationController?.pushViewController(webVc, animated: true)
            }.catch { (error) in
                self.whisper(message: "Your transaction is currently pending.")
        }
    }
    
}

extension TransactionDetailsViewController: QRCodeReaderViewControllerDelegate {
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
}


