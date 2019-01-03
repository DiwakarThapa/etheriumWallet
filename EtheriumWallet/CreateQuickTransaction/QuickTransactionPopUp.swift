//
//  QuickTransactionPopUp.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/14/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit
import DropDown

struct QuickTransactionStructure {
    
    var amount: Double?
    var currency: CurrencyModel?
}

class QuickTransactionPopUp: UIView {


    @IBOutlet weak var proceedBtn: UIButton!
    @IBOutlet weak var currencyField: UITextField!
    @IBOutlet weak var dialogView: UIView!
    @IBOutlet weak var amountField: UITextField!
    
    var didFinishAdding: ((QuickTransactionStructure) -> ())?
    var tokens: [CurrencyModel]? {
        didSet {
            if let tokensArray = tokens {
                dropdown.dataSource = tokensArray.compactMap{$0.tokenName}
                dropdown.reloadAllComponents()
            }
        }
    }
    var selectedToken: CurrencyModel?
    let dropdown = DropDown()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        loadFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadFromNib() {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "QuickTransactionPopUp", bundle: bundle)
        if  let popup = nib.instantiate(withOwner: self, options: nil).first as? UIView {
            popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            popup.frame = self.bounds
            addSubview(popup)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dialogView.layer.cornerRadius = 5.0
        proceedBtn.layer.cornerRadius = 5.0
    }
    
    func setup() {
        getTokensData()
        self.currencyField.delegate = self
        self.dropdown.anchorView = currencyField
        dropdown.direction = .bottom
        dropdown.selectionAction = { (index, item) in
            self.currencyField.text = item
            self.selectedToken = self.tokens?[index]
        }
        dropdown.dismissMode = .automatic
        self.currencyField.addTarget(self, action: #selector(tokenDropDown), for: .allTouchEvents)
    }
    
    @objc private func tokenDropDown() {
        dropdown.show()
    }
    
    
    
    // IBActions
    @IBAction func dissmissBtn(_ sender: Any) {
        dissmiss()
    }
    
    @IBAction func proceedAction(_ sender: Any) {
        let structure = QuickTransactionStructure(amount: Double(self.amountField.text ?? ""), currency: self.selectedToken)
        didFinishAdding?(structure)
        self.dissmiss()
    }
    
    func getTokensData() {
        let tokens = realm.objects(CurrencyModel.self)
        self.tokens = Array(tokens)
    }
    
}



extension QuickTransactionPopUp {
    
    func present() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        dialogView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        //self.alpha = 0
        appDelegate?.window?.addSubview(self)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseOut, animations: {() -> Void in
            
            self.dialogView.transform = CGAffineTransform.identity
            //self.alpha = 1
            
        }, completion: { _ in
            
        })
    }
    
    func dissmiss() {
        self.alpha = 1
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseOut, animations: {() -> Void in
            self.dialogView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0
            
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

extension QuickTransactionPopUp : UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.currencyField {
            return false
        }
        return true
    }
}
