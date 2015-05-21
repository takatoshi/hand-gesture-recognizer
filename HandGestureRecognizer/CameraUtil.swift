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

class CameraUtil {
    
    // sampleBufferからUIImageへ変換
    class func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage {
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
    
    class func videoOrientationFromDeviceOrientation(deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        let orientation: AVCaptureVideoOrientation
        switch (deviceOrientation) {
        case UIDeviceOrientation.Unknown:
            orientation = AVCaptureVideoOrientation.Portrait
        case UIDeviceOrientation.Portrait:
            orientation = AVCaptureVideoOrientation.Portrait
        case UIDeviceOrientation.PortraitUpsideDown:
            orientation = AVCaptureVideoOrientation.PortraitUpsideDown
        case UIDeviceOrientation.LandscapeLeft:
            orientation = AVCaptureVideoOrientation.LandscapeRight
        case UIDeviceOrientation.LandscapeRight:
            orientation = AVCaptureVideoOrientation.LandscapeLeft
        case UIDeviceOrientation.FaceUp:
            orientation = AVCaptureVideoOrientation.Portrait
        case UIDeviceOrientation.FaceDown:
            orientation = AVCaptureVideoOrientation.Portrait
        }
        
        return orientation
    }
}