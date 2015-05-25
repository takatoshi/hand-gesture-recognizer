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
    let cameraManager: CameraManager = CameraManager()

    private let pageCount = 3
    private var currentPage = 0
    private var gestureMode: Int = 0
    private var frameCount: Int = 0
    private var isScrolling: Bool = false
    private var isGestureEnabled: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        cameraManager.initCamera(sampleBufferDelegate: self)
        
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdatesToQueue( NSOperationQueue.currentQueue(), withHandler:{
            deviceManager, error in
            let accel: CMAcceleration = deviceManager.userAcceleration
            if pow(accel.x, 2) + pow(accel.y, 2) + pow(accel.z, 2) > 1 / 1000 {
                self.isGestureEnabled = false
            } else if !self.isScrolling {
                self.isGestureEnabled = true
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        self.currentPage = Int(self.scrollView.contentOffset.x / self.scrollView.bounds.width)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.setVideoOrientation()
        setupScrollView()
        scrollToPage(self.currentPage)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupScrollView() {
        self.scrollView.subviews.map { $0.removeFromSuperview() }
        for i in 0..<self.pageCount {
            let x: CGFloat = self.view.bounds.width * CGFloat(i)
            let y: CGFloat = 0
            let width: CGFloat  = self.view.bounds.width
            let height: CGFloat = self.view.bounds.height
            let frame:CGRect = CGRect(x: x, y: y, width: width, height: height)
            let imageView = UIImageView(frame: frame)
            let image = UIImage(named: "menu\(i + 1)")
            imageView.image = image
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            self.scrollView.addSubview(imageView)
        }
        self.scrollView.contentSize = CGSizeMake(self.view.bounds.width * CGFloat(self.pageCount), self.view.bounds.height)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        dispatch_sync(dispatch_get_main_queue(), {
            if ++self.frameCount % 2 != 0 {
                return
            }
            if !self.isGestureEnabled {
                return
            }
            
            // UIImageへ変換
            var image: UIImage = self.cameraManager.imageFromSampleBuffer(sampleBuffer)
            
            // ジェスチャー認識
            image = self.detector.detectGesture(image, mode: self.gestureMode)
            
            // 表示
            self.imageView.image = image
            
            let gestureType = self.detector.getGestureType()
            switch gestureType {
            case .Left:
                self.scrollBack()
            case .Right:
                self.scrollNext()
            case .None:
                break
            }
        })
    }
    
    private func scrollNext() {
        let currentPage: Int = Int(self.scrollView.contentOffset.x / self.scrollView.bounds.width)
        let nextPage: Int = currentPage == self.pageCount - 1 ? self.pageCount - 1 : currentPage + 1
        scrollToPage(nextPage)
    }
    
    private func scrollBack() {
        let currentPage: Int = Int(self.scrollView.contentOffset.x / self.scrollView.bounds.width)
        let backPage: Int = currentPage == 0 ? 0 : currentPage - 1
        scrollToPage(backPage)
    }
    
    private func scrollToPage(pageNum: Int) {
        self.currentPage = pageNum
        let frame: CGRect = self.scrollView.frame;
        let offset: CGPoint = CGPoint(x: frame.size.width * CGFloat(pageNum), y: 0)
        self.scrollView.setContentOffset(offset, animated: true)
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        self.gestureMode = sender.selectedSegmentIndex
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.isGestureEnabled = false
        self.isScrolling = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.isGestureEnabled = true
        self.isScrolling = false
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.isGestureEnabled = true
        self.isScrolling = false
    }
}