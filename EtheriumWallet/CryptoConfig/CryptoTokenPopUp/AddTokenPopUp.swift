//
//  AddTokenPopUp.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/14/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit

class AddTokenPopUp: UIView {

    @IBOutlet weak var dialogView: UIView!
    @IBOutlet weak var tokenNameField: UITextField!
    @IBOutlet weak var contractAddressField: UITextField!
    @IBOutlet weak var addTokenBtn: UIButton!
    
    var didFinishAdding: (() -> ())?
    
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        loadFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadFromNib() {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "AddTokenPopUp", bundle: bundle)
        if  let popup = nib.instantiate(withOwner: self, options: nil).first as? UIView {
            popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            popup.frame = self.bounds
            addSubview(popup)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dialogView.layer.cornerRadius = 5.0
        addTokenBtn.layer.cornerRadius = 5.0
    }
    
    // IBActions
    @IBAction func dissmissBtn(_ sender: Any) {
        dissmiss()
    }
    
    @IBAction func addTokenAction(_ sender: Any) {
        let model = CurrencyModel()
        model.contractAddress = self.contractAddressField.text
        model.tokenName = self.tokenNameField.text
        try? realm.write {
            realm.add(model)
        }
        didFinishAdding?()
        self.dissmiss()
    }
    
}



extension AddTokenPopUp {
    
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
