//
//  ViewController.swift
//  qrScanDemo
//
//  Created by yetaiwen on 2019/4/18.
//  Copyright © 2019年 yetaiwen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var resultLal: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "扫描二维码"
        
    }
    
    @IBAction func scanQR(_ sender: UIButton) {
        let qrController = TTQRViewController.init()
        qrController.resultDelegate = self
        self.navigationController?.pushViewController(qrController, animated: true)
    }
    
}

extension ViewController: TTQRScanDelegate {
    func tt_handleQRScanResult(result: String) {
        resultLal.text = result
    }
}

