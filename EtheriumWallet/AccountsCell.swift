//
//  AccountsCell.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 2/9/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import Geth
class AccountsCell: UITableViewCell {

 
    @IBOutlet weak var addressKey: UILabel!
    
    var account: iGethAccount?
    
    func setup() {
        self.addressKey.text = "Address-Key: \(account?.getAddress().getHex() ?? "")"
    }
}
