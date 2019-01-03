//
//  TokenDetailViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/14/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import QRCode

class TokenDetailViewController: UIViewController {

    @IBOutlet weak var tokenQRView: UIImageView!
    @IBOutlet weak var tokenTextView: UITextView!
    @IBOutlet weak var tokenLabel: UILabel!
    
    var model: CurrencyModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tokenTextView.text = model?.contractAddress
        self.tokenLabel.text = model?.tokenName
        let qr = QRCode(model?.contractAddress ?? "")
        self.tokenQRView.image = qr?.image
    }

}
