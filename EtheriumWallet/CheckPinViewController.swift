//
//  CheckPinViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 2/9/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import PinCodeTextField
import IQKeyboardManagerSwift
class CheckPinViewController: UIViewController {

    @IBOutlet weak var pinVeiw: PinCodeTextField!
    
    var checkPin:((String) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pinVeiw.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pinVeiw.becomeFirstResponder()
    }


    fileprivate func sendPin() {
        if pinVeiw.text?.characters.count == 4 {
            checkPin?(self.pinVeiw.text ?? "")
            self.dismiss(animated: true, completion: nil)
        }
    }


}

extension CheckPinViewController: PinCodeTextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: PinCodeTextField) {
        self.sendPin()
    }
}
