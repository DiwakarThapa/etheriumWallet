//
//  AddCryptoTokenViewController.swift
//  EtheriumWallet
//
//  Created by Lizan Pradhanang on 5/13/18.
//  Copyright © 2018 Lizan Pradhanang. All rights reserved.
//

import UIKit

class AddCryptoTokenViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var tokens: [CurrencyModel]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addTokens))
        self.tableView.dataSource = self
        self.tableView.delegate = self
        fetchTokenData()
    }
    
    private func fetchTokenData() {
        let tokens = realm.objects(CurrencyModel.self)
        self.tokens = Array(tokens)
    }
    
    @objc func addTokens() {
        let popUp = AddTokenPopUp()
        popUp.didFinishAdding = {
            self.whisperSuccessWith(message: "Token added successfully.", completion: { () -> (Void) in
                self.fetchTokenData()
            })
        }
        popUp.present()
    }

}

extension AddCryptoTokenViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokens?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TokenTableViewCell") as! TokenTableViewCell
        cell.model = tokens?[indexPath.row]
        return cell
    }
}

extension AddCryptoTokenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TokenTableViewCell
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "TokenDetailViewController") as! TokenDetailViewController
        vc.model = cell.model
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
