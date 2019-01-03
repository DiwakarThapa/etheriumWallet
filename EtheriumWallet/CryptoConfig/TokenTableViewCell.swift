//
//  TokenTableViewCell.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/13/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit

class TokenTableViewCell: UITableViewCell {

    @IBOutlet weak var tokenNameLabel: UILabel!
    
    var model: CurrencyModel? {
        didSet {
            self.tokenNameLabel.text = model?.tokenName
        }
    }
}
