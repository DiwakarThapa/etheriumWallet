//
//  CurrencyModel.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/13/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import Foundation
import RealmSwift

class CurrencyModel: Object {
    
    @objc dynamic var contractAddress: String?
    @objc dynamic var tokenName: String?
}
