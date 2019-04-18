//
//  TTQRViewController.swift
//  CloudCar
//
//  Created by yetaiwen on 2019/4/17.
//  Copyright © 2019年 yetaiwen. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

protocol TTQRScanDelegate {
    func tt_handleQRScanResult(result: String);
}


class TTQRViewController: UIViewController {
    
    var resultDelegate: TTQRScanDelegate?
    
    var captureDevice: AVCaptureDevice?
    
    var captureInput: AVCaptureDeviceInput?
    
    var mataOutput: AVCaptureMetadataOutput?
    
    var captureSession: AVCaptureSession?
    
    var capturePreView: AVCaptureVideoPreviewLayer?
    
    lazy var interestRect: CGRect = {
        let rect = CGRect.init(x: self.view.bounds.size.width/4, y: self.view.bounds.size.height/2-self.view.bounds.size.width/4, width: self.view.bounds.size.width/2, height: self.view.bounds.size.width/2)
        return rect
    }()
    
    var scanView: UIView?
    
    var torchTag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "扫一扫"
        
        setupCoverView()
        setupInterestRectBoard()
        setupScanLine()
        setupBottomView()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupCaptureSession()
        
        startScan()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if torchTag {
        try? captureDevice?.lockForConfiguration()
        captureDevice?.torchMode = .off
        captureDevice?.unlockForConfiguration()
        torchTag = false
        }
    }
    
    func startScan() {
        scanView?.isHidden = false
        let animation = CABasicAnimation.init(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = self.interestRect.size.height
        animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.duration = 3
        animation.isRemovedOnCompletion = false
        animation.repeatCount = MAXFLOAT
        scanView?.layer.add(animation, forKey: "y_transaltion")
        if ((captureSession?.isRunning)!) {
            return
        }
        captureSession?.startRunning()
    }
    
    func endScan() {
        if (!(captureSession?.isRunning)!) {
            return
        }
        captureSession?.stopRunning()
        scanView?.isHidden = true
        scanView?.layer.removeAnimation(forKey: "y_transaltion")
    }
    
    func setupScanLine() {
        scanView = UIView.init(frame: CGRect.init(x: self.interestRect.origin.x+1, y: self.interestRect.origin.y+1, width: self.interestRect.size.width-2, height: 0.5))
        scanView!.backgroundColor = UIColor.white
        scanView!.isHidden = true
        self.view.addSubview(scanView!)
        
    }
    
    func setupInterestRectBoard() {
        let interestBoardLayer = CAShapeLayer.init()
        
        let rect = CGRect.init(x: self.interestRect.origin.x+0.5, y: self.interestRect.origin.y+0.5, width: self.interestRect.size.width-1, height: self.interestRect.size.height-1)
        let path = UIBezierPath.init(rect: rect)
        interestBoardLayer.path = path.cgPath
        interestBoardLayer.strokeColor = UIColor.white.cgColor
        interestBoardLayer.fillColor = UIColor.clear.cgColor
        
        self.view.layer.addSublayer(interestBoardLayer)
    }
    
    func setupCoverView() {
        let coverLayer = CALayer.init()
        coverLayer.frame = self.view.frame
        coverLayer.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.35).cgColor
        
        let maskLayer = CAShapeLayer.init()
        let path = UIBezierPath.init(rect: self.view.frame)
        let path1 = UIBezierPath.init(rect: self.interestRect).reversing()
        path.append(path1)
        maskLayer.path = path.cgPath
        
        coverLayer.mask = maskLayer
        
        self.view.layer.addSublayer(coverLayer)
    }
    
    
    func setupBottomView() {
        let bottomView = UIView.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height-60, width: self.view.frame.size.width, height: 60))
        bottomView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        self.view.addSubview(bottomView)
        
        let lampBtn = UIButton.init(frame: CGRect.init(x: self.view.bounds.size.width/4-22, y: 8, width: 44, height: 44))
        lampBtn.setImage(UIImage.init(named: "shoudiantong"), for: .normal)
        lampBtn.addTarget(self, action: #selector(openLamp(_:)), for: .touchUpInside)
        bottomView.addSubview(lampBtn)
        
        let albumBtn = UIButton.init(frame: CGRect.init(x: 3*self.view.bounds.size.width/4-22, y: 8, width: 44, height: 44))
        albumBtn.setImage(UIImage.init(named: "xiangce"), for: .normal)
        albumBtn.addTarget(self, action: #selector(openAlbum(_:)), for: .touchUpInside)
        bottomView.addSubview(albumBtn)
    }
    
    @objc func openLamp(_ sender: UIButton) {
        if ((captureDevice?.hasTorch)!) {
            if (!torchTag) {
                try? captureDevice?.lockForConfiguration()
                try? captureDevice?.setTorchModeOn(level: 0.6)
                captureDevice?.unlockForConfiguration()
                torchTag = true
            }else {
                try? captureDevice?.lockForConfiguration()
                captureDevice?.torchMode = .off
                captureDevice?.unlockForConfiguration()
                torchTag = false
            }
        }
    }
    
    @objc func openAlbum(_ sender: UIButton) {
        let imageController = UIImagePickerController.init()
        imageController.sourceType = .photoLibrary
        imageController.delegate = self
        self.present(imageController, animated: true, completion: nil)
    }
    
    func setupCaptureSession() {
        
        captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            try captureInput = AVCaptureDeviceInput.init(device: captureDevice!)
        }catch {
            
        }
        
        mataOutput = AVCaptureMetadataOutput.init()
        mataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        captureSession = AVCaptureSession.init()
        
        if ((captureSession?.canAddInput(captureInput!))!) {
            captureSession?.addInput(captureInput!)
        }
        
        if ((captureSession?.canAddOutput(mataOutput!))!) {
            captureSession?.addOutput(mataOutput!)
        }
        
        if ((captureSession?.canSetSessionPreset(AVCaptureSession.Preset.high))!) {
            captureSession?.sessionPreset = .high
        }
        
        mataOutput?.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        capturePreView = AVCaptureVideoPreviewLayer.init(session: captureSession!)
        
        capturePreView?.frame = self.view.frame
        self.view.layer.insertSublayer(capturePreView!, at: 0)
        
        captureSession?.startRunning()
        
        let rect = capturePreView!.metadataOutputRectConverted(fromLayerRect: self.interestRect)
        
        mataOutput?.rectOfInterest = rect
        
    }
    
    @objc func backAction(_ sender: UIBarButtonItem) {
        endScan()
        self.navigationController?.popViewController(animated: true)
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension TTQRViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if (metadataObjects.count == 0) {
            return
        }
        endScan()
        let object = metadataObjects.first as! AVMetadataMachineReadableCodeObject
        let result = object.stringValue
        if self.resultDelegate != nil {
            self.resultDelegate?.tt_handleQRScanResult(result: result!)
        }
        self.navigationController?.popViewController(animated: true)
        
    }
}

extension TTQRViewController: UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            let img = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            let decteor = CIDetector.init(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            //let ciimg = img.ciImage
            //let ciimg = CIImage.init(image: img)
            //let ciimg = CIImage.init(data: img.pngData()!)
            let ciimg = CIImage.init(cgImage: img.cgImage!)
            let fetures = decteor?.features(in: ciimg)
            if (fetures?.count)! > 0 {
                if let qrFeture = fetures?.first as? CIQRCodeFeature {
                    self.endScan()
                    if (self.resultDelegate != nil) {
                        self.resultDelegate?.tt_handleQRScanResult(result: qrFeture.messageString!)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            }else {
                print("没有二维码信息")
            }
        }
        
    }
}
