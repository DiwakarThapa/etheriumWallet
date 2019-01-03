//
//  ViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 2/9/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import Geth
import Floaty
import QRCodeReader

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var error: NSError?
     var ks:iGethAccountManager?
    var accounts = [iGethAccount]()

    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        ks = iGethNewAccountManager(datadir + "/etherKeyStore", iGethLightScryptN, iGethLightScryptP)
        tableView.delegate = self
        tableView.dataSource = self
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addNewAccount))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "+ Token", style: .plain, target: self, action: #selector(addToken))
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        let floaty = Floaty()
        floaty.size = 60
        floaty.plusColor = UIColor.white
        floaty.buttonColor = UIColor.init(hex: "#267A16")
        floaty.itemSize = 50
        floaty.addItem(icon: UIImage.init(named: "transaction")) { (item) in
            self.readerVC.delegate = self
            
            // Or by using the closure pattern
            self.readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                let webVc = WebLinksViewController()
                webVc.url = "https://ropsten.etherscan.io/tx/" + (result?.value ?? "")
                webVc.titleString = "Transaction Details"
                self.navigationController?.pushViewController(webVc, animated: true)
            }
            // Presents the readerVC as modal form sheet
            self.readerVC.modalPresentationStyle = .formSheet
            self.present(self.readerVC, animated: true, completion: nil)
        }
        self.view.addSubview(floaty)
    }
    
    @objc private func addToken() {
        let vc = UIStoryboard.init(name: "AddCryptoToken", bundle: nil).instantiateViewController(withIdentifier: "AddCryptoTokenViewController") as! AddCryptoTokenViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.accounts = []
        fetchAccounts()
    }

    @objc private func addNewAccount() {
        self.navigationController?.pushViewController(self.storyboard?.instantiateViewController(withIdentifier: "NewAccountViewController") as! NewAccountViewController, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fetchAccounts() {
        let accounts = ks?.getAccounts()
        for i in 0 ... 10 {
            if let account = try? accounts?.get(i) {
                if let ac = account {
                    self.accounts.append(ac)
                    self.tableView.reloadData()
                }else{
                    return
                }
            }else{
                return
            }
        }
        
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getCell()
        cell.account = accounts[indexPath.row]
        cell.setup()
        return cell
    }
    
    private func getCell() -> AccountsCell {
        return tableView.dequeueReusableCell(withIdentifier: "AccountsCell") as! AccountsCell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! AccountsCell
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AccountDetailsViewController") as! AccountDetailsViewController
        vc.account = cell.account
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! AccountsCell
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CheckPinViewController") as! CheckPinViewController
            vc.checkPin = {code in
                do {
                    try self.ks?.delete(cell.account!, passphrase: code)
                }catch {
                    print("invalid pin")
                }
            }
            self.present(vc, animated: true, completion: nil)
            
        }
    }
}

import Whisper

extension UIViewController {
    func whisper(message: String) {
        let message = Message(title: message, backgroundColor: .red)
        // Show and hide a message after delay
        if let nav = self.navigationController {
            Whisper.show(whisper: message, to: nav, action: .show)
        }
    }
    
    func whisperSuccess(message: String) {
        let message = Message(title: message , backgroundColor: UIColor.init(hex: "#71A8DE"))
        if let nav = self.navigationController {
            Whisper.show(whisper: message, to: nav, action: .show)
        }
    }
    
    func whisperSuccessWith(message: String, completion: (() -> (Void))? ) {
        let message = Message(title: message , backgroundColor: UIColor.init(hex: "#71A8DE"))
        if let nav = self.navigationController {
            Whisper.show(whisper: message, to: nav, action: .show)
            completion?()
        }
    }
}

extension ViewController: QRCodeReaderViewControllerDelegate {
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
}
