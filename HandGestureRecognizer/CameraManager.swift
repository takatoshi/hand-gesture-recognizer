//
//  CameraUtil.swift
//  HandGestureRecognizer
//
//  Created by Takatoshi Kobayashi on 2015/05/21.
//  Copyright (c) 2015年 Takatoshi Kobayashi. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CameraManager {
    
    var mySession: AVCaptureSession!
    var myDevice: AVCaptureDevice!
    var myOutput: AVCaptureVideoDataOutput!
    
    func initCamera(#sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!) -> Void {
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
            return
        }
        
        let myInput = AVCaptureDeviceInput.deviceInputWithDevice(myDevice, error: nil) as! AVCaptureDeviceInput
        
        if mySession.canAddInput(myInput) {
            mySession.addInput(myInput)
        } else {
            return
        }
        
        var lockError: NSError?
        if myDevice.lockForConfiguration(&lockError) {
            if let error = lockError {
                println("lock error: \(error.localizedDescription)")
                return
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
            return
        }
        
        let queue: dispatch_queue_t = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL)
        myOutput.setSampleBufferDelegate(sampleBufferDelegate, queue: queue)
                
        self.setVideoOrientation()
        
        mySession.startRunning()
    }


    
    // sampleBufferからUIImageへ変換
    func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        // ベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        // 画像データの情報を取得
        let baseAddress: UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        
        // RGB色空間を作成
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        // Bitmap graphic contextを作成
        let bitsPerCompornent: Int = 8
        var bitmapInfo = CGBitmapInfo((CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue))
        let newContext: CGContextRef = CGBitmapContextCreate(baseAddress, width, height, bitsPerCompornent, bytesPerRow, colorSpace, bitmapInfo) as CGContextRef
        // Quartz imageを作成
        let imageRef: CGImageRef = CGBitmapContextCreateImage(newContext)
        
        // UIImageを作成
        let resultImage: UIImage = UIImage(CGImage: imageRef)!
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        return resultImage
    }
    
    func setVideoOrientation(interfaceOrientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation) {
        for connection in myOutput.connections {
            if let conn = connection as? AVCaptureConnection where conn.supportsVideoOrientation {
                conn.videoOrientation = self.videoOrientationFromDeviceOrientation(interfaceOrientation)
            }
        }
    }
    
    private func videoOrientationFromDeviceOrientation(interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        let orientation: AVCaptureVideoOrientation
        switch (interfaceOrientation) {
        case .Unknown:
            orientation = AVCaptureVideoOrientation.Portrait
        case .Portrait:
            orientation = AVCaptureVideoOrientation.Portrait
        case .PortraitUpsideDown:
            orientation = AVCaptureVideoOrientation.PortraitUpsideDown
        case .LandscapeLeft:
            orientation = AVCaptureVideoOrientation.LandscapeLeft
        case .LandscapeRight:
            orientation = AVCaptureVideoOrientation.LandscapeRight
        }
        
        return orientation
    }
}