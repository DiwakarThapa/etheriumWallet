//
//  QuickTransactionViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/14/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import QRCode

class QuickTransactionViewController: UIViewController {

    @IBOutlet weak var transactionQRView: UIImageView!
    
    var data: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let qr = QRCode(data ?? "")
        self.transactionQRView.image = qr?.image
    }

}
