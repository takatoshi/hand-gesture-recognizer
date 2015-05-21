//
//  ViewController.swift
//  HandGestureRecognizer
//
//  Created by Takatoshi Kobayashi on 2015/05/21.
//  Copyright (c) 2015年 Takatoshi Kobayashi. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!

    var mySession: AVCaptureSession!
    var myDevice: AVCaptureDevice!
    var myOutput: AVCaptureVideoDataOutput!
    
    let detector = Detector()
    let motionManager: CMMotionManager = CMMotionManager()

    private let pageCount = 3
    private var gestureMode: Int = 0
    private var isGestureEnabled: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        
        if initCamera() {
            mySession.startRunning()
        }
        
        motionManager.deviceMotionUpdateInterval = 0.05
        // Start motion data acquisition
        motionManager.startDeviceMotionUpdatesToQueue( NSOperationQueue.currentQueue(), withHandler:{
            deviceManager, error in
            var accel: CMAcceleration = deviceManager.userAcceleration
            if pow(accel.x, 2) + pow(accel.y, 2) + pow(accel.z, 2) > 1 / 7000 {
                self.isGestureEnabled = false
                println("MOVE")
            } else {
                self.isGestureEnabled = true
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupScrollView() {
        for i in 0..<self.pageCount {
            var x: CGFloat = self.view.bounds.width * CGFloat(i)
            var y: CGFloat = 0
            var width: CGFloat  = self.view.bounds.width
            var height: CGFloat = self.view.bounds.height
            var frame:CGRect = CGRect(x: x, y: y, width: width, height: height)
            let imageView = UIImageView(frame: frame)
            let image = UIImage(named: "menu\(i + 1)")
            imageView.image = image
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            self.scrollView.addSubview(imageView)
        }
        self.scrollView.contentSize = CGSizeMake(self.view.bounds.width * CGFloat(self.pageCount), self.view.bounds.height)
    }

    
    private func initCamera() -> Bool {
        mySession = AVCaptureSession()
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            mySession.sessionPreset = AVCaptureSessionPreset640x480
        } else {
            mySession.sessionPreset = AVCaptureSessionPresetPhoto
        }
        
        for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            if (device.position == AVCaptureDevicePosition.Front) {
                myDevice = device as! AVCaptureDevice
            }
        }
        if myDevice == nil {
            return false
        }
        
        let myInput = AVCaptureDeviceInput.deviceInputWithDevice(myDevice, error: nil) as! AVCaptureDeviceInput
        
        if mySession.canAddInput(myInput) {
            mySession.addInput(myInput)
        } else {
            return false
        }
        
        var lockError: NSError?
        if myDevice.lockForConfiguration(&lockError) {
            if let error = lockError {
                println("lock error: \(error.localizedDescription)")
                return false
            } else {
                myDevice.activeVideoMinFrameDuration = CMTimeMake(1, 60)
                myDevice.unlockForConfiguration()
            }
        }
        
        myOutput = AVCaptureVideoDataOutput()
        myOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]
        myOutput.alwaysDiscardsLateVideoFrames = true
        
        if mySession.canAddOutput(myOutput) {
            mySession.addOutput(myOutput)
        } else {
            return false
        }
        
        let queue: dispatch_queue_t = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL)
        myOutput.setSampleBufferDelegate(self, queue: queue)
        
        for connection in myOutput.connections {
            if let conn = connection as? AVCaptureConnection where conn.supportsVideoOrientation {
                conn.videoOrientation = CameraUtil.videoOrientationFromDeviceOrientation(UIDevice.currentDevice().orientation)
            }
        }
        
        var previewLayer = AVCaptureVideoPreviewLayer(session: mySession)
        previewLayer.frame = self.view.bounds
        previewLayer.contentsGravity = kCAGravityResizeAspectFill
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
//        self.view.layer.insertSublayer(previewLayer, atIndex: 0)
        
        return true
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        dispatch_sync(dispatch_get_main_queue(), {
            
            // UIImageへ変換
            var image: UIImage = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            
            // ジェスチャー認識
            image = self.detector.recognizeGesture(image, mode: self.gestureMode)
            
            // 表示
//            self.imageView.image = image
            
            if !self.isGestureEnabled {
                return
            }
            
            var gestureType = Int(self.detector.getGestureType())
            if gestureType == 1 {
                self.scrollBack()
            } else if gestureType == 2 {
                self.scrollNext()
            }
        })
    }
    
    private func scrollNext() {
        let currentPage: Int = Int(self.scrollView.contentOffset.x / self.scrollView.bounds.width)
        let nextPage: Int = currentPage == self.pageCount - 1 ? self.pageCount - 1 : currentPage + 1
        var frame: CGRect = self.scrollView.frame;
        frame.origin.x = frame.size.width * CGFloat(nextPage)
        frame.origin.y = 0;
        self.scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    private func scrollBack() {
        let currentPage: Int = Int(self.scrollView.contentOffset.x / self.scrollView.bounds.width)
        let backPage: Int = currentPage == 0 ? 0 : currentPage - 1
        var frame: CGRect = self.scrollView.frame;
        frame.origin.x = frame.size.width * CGFloat(backPage)
        frame.origin.y = 0;
        self.scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        self.gestureMode = sender.selectedSegmentIndex
    }
}