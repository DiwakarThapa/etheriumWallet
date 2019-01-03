//
//  ViewController.swift
//  KeythereumSwift
//
//  Created by Seiji.Y. on 2017/12/07.
//  Copyright © 2017年 Seiji.Y. All rights reserved.
//

import UIKit
import WebKit
import QRCode
import MBProgressHUD

extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

class KeyGeneratorViewController: UIViewController {

    @IBOutlet weak var privateQRView: UIImageView!
    @IBOutlet weak var secretKeyLabel:UITextView!
    
    let hud = MBProgressHUD()
    
    // ダミーのWebview. JS実行用
    //var webView = UIWebView()
    var webView = WKWebView()
    var jsonKey : String?
    var password: String?
    var privateKey: String?
    // テキストフィールド外をタップするとキーボードを隠す
    @IBAction func hiddenKeyboard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    @objc private func extractPrivateKey() {
        
        // javascript:privateKey()のパラメタ
        var param1:String = ""
        let param2 = password!
        // keyStoreTextの複数行を１行にする
        jsonKey?.enumerateLines { (line, stop) -> () in
            param1 += line.trimmingCharacters(in:.whitespacesAndNewlines)
        }
        
        // js評価文字列作成
        let jsEvalStr = "privateKey('" + param1 + "','" + param2 + "');"
        
        //let privateKey = webView.stringByEvaluatingJavaScript(from:jsEvalStr)
        
        webView.evaluateJavaScript(jsEvalStr, completionHandler: {(res,error) in
            self.hideProgressHud()
            guard let pk = res else {
                self.secretKeyLabel.text = "fail to decode private key"
                return
            }
            
            self.secretKeyLabel.text = pk as? String
            let qr = QRCode(self.secretKeyLabel.text)
            self.privateQRView.image = qr?.image
            self.didRecievePrivateKey?(self.secretKeyLabel.text ?? "")
        })

    }

    var didRecievePrivateKey: ((String) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showProgressHudWith(title: "Generating Private Key.")
        if let data = UserDefaults.standard.dictionary(forKey: Constants.wallet) {
            self.jsonKey = data["jsonData"] as? String
        }
        // Do any additional setup after loading the view, typically from a nib.
        
        // ローカルのkeythereum.htmlをロード
//        let html = Bundle.main.path(forResource: "keythereum", ofType: "html")
//        webView.loadRequest(URLRequest(url: URL(string: html!)!))
        
        let url = Bundle.main.url(forResource: "keythereum", withExtension: ".html")!
        let urlRequest = URLRequest(url: url)
        webView.load(urlRequest)
        
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(extractPrivateKey), userInfo: nil, repeats: false)
        // パスワードフィールドを伏せ字モードに

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


