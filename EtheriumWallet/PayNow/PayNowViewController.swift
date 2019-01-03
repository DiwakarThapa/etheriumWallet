//
//  PayNowViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/14/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import Web3
import BigInt
import PromiseKit
import QRCode

struct PayNowStructure {
    var amount: String?
    var type: String?
    var contractAddress: String?
    var toAddress: String?
}

class PayNowViewController: UIViewController {

    var hex: String?
    var privateKey: String?
    var transactionHash: String?
    
    @IBOutlet weak var transactionHexQRView: UIImageView!
    
    var priceHex:String = ""
    var toHex = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let data = Data.init(hex: hex ?? "")
        let structure = self.getPayNowData(value: data)
        self.showProgressHudWith(title: "Transfering ...")
        if structure.type == "ETH" {
            self.transferEth(structure: structure)
        }else {
            self.transferToken(structure: structure)
        }
    }
    
    @IBAction func viewTransactionAction(_ sender: Any) {
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
    
    func transferToken(structure: PayNowStructure) {
        let transfer = "0xa9059cbb"
        let n = (Int(Double(structure.amount  ?? "") ?? 0)*1000)
        let hexString = String(format:"%2X", n)
        
        for _ in 0 ..< 64 - (hexString.count) {
            priceHex.append("0")
        }
        let price = priceHex + hexString
        var to = structure.toAddress ?? ""
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
        
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: self.privateKey ?? "")
        firstly {
            web3.eth.getTransactionCount(address: privateKey.address, block: .latest)
            }.then { nonce in
                Promise { seal in
                    var tx = try EthereumTransaction(
                        nonce: nonce,
                        gasPrice: EthereumQuantity(quantity: 21.gwei),
                        gasLimit: 60000,
                        to: EthereumAddress(hex: structure.contractAddress ?? "", eip55: false),
                        value: EthereumQuantity(quantity: BigUInt.init(0)),
                        data: EthereumData.init(bytes: contractData.bytes),
                        chainId: 3
                    )
                    try! tx.sign(with: privateKey)
                    seal.resolve(tx, nil)
                }
            }.then { tx in
                web3.eth.sendRawTransaction(transaction: tx)
            }.done { hash in
                self.hideProgressHud()
                let qr = QRCode(hash.hex())
                self.transactionHexQRView.image = qr?.image
                self.transactionHash = hash.hex()
                self.whisperSuccess(message: "Transaction completed.")
            }.catch { error in
                self.hideProgressHud()
                self.whisper(message: error.localizedDescription)
        }
    }
    
    func transferEth(structure: PayNowStructure) {
        if self.privateKey != "" {
            let amount = Int.init((Double(structure.amount ?? "") ?? 0)*1000000000000000000)
            
            let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + (self.privateKey ?? ""))
            firstly {
                web3.eth.getTransactionCount(address: privateKey.address, block: .latest)
                }.then { nonce in
                    Promise { seal in
                        var tx = try EthereumTransaction(
                            nonce: nonce,
                            gasPrice: EthereumQuantity(quantity: 21.gwei),
                            gasLimit: 21000,
                            to: EthereumAddress(hex: structure.toAddress ?? "", eip55: false),
                            value: EthereumQuantity(quantity: BigUInt.init(amount)),
                            chainId: 3
                        )
                        try! tx.sign(with: privateKey)
                        seal.resolve(tx, nil)
                    }
                }.then { tx in
                    web3.eth.sendRawTransaction(transaction: tx)
                }.done { hash in
                    self.hideProgressHud()
                    let qr = QRCode(hash.hex())
                    self.transactionHexQRView.image = qr?.image
                    self.transactionHash = hash.hex()
                    self.whisperSuccess(message: "Transaction completed.")
                    
                }.catch { error in
                    self.hideProgressHud()
                    self.whisper(message: error.localizedDescription)
            }
        }else {
            self.hideProgressHud()
            self.whisper(message: "Please unlock your wallet first.")
        }
    }

}

extension UIViewController {
    
    func getPayNowData(value: Data) -> PayNowStructure {
        let value = String(decoding: value, as: UTF8.self).components(separatedBy: " ")
        return PayNowStructure(amount: value[1], type: value[2], contractAddress: value[3], toAddress: value[5])
    }
}
