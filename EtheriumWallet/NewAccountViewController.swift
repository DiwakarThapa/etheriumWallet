//
//  NewAccountViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 2/9/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import PinCodeTextField
import Geth

class NewAccountViewController: UIViewController {

    @IBOutlet weak var pinView: PinCodeTextField!
    var ks:iGethAccountManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        ks = iGethNewAccountManager(datadir + "/etherKeyStore", iGethLightScryptN, iGethLightScryptP)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(addAccount))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pinView.becomeFirstResponder()
    }
    
    @objc private func addAccount() {
        if pinView.hasText && pinView.text?.count == 4 {
            do {
                _ = try ks?.newAccount(pinView.text ?? "")
                self.navigationController?.popViewController(animated: true)
            } catch {
                
            }
        }

    }
}

