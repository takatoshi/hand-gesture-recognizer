//
//  Detector.m
//  HandGestureRecognizer
//
//  Created by Takatoshi Kobayashi on 2015/05/21.
//  Copyright (c) 2015年 Takatoshi Kobayashi. All rights reserved.
//
#import "HandGestureRecognizer-Bridging-Header.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#import <opencv2/video/background_segm.hpp>

using namespace cv;

@interface Detector()
{
    Mat frame;
    Mat curr;
    Mat prev;
    Ptr<BackgroundSubtractor> bgs;
    cv::Point prevCenter;
    float delta;
    GestureType gestureType;
    bool gestureEnabled;
}
@end

@implementation Detector: NSObject

- (id)init {
    self = [super init];
    
    bgs = new BackgroundSubtractorMOG2(0, 0, false);
    gestureType = GestureType::RIGHT;
    
    return self;
}

- (UIImage *)recognizeGesture:(UIImage *)image mode:(NSInteger)mode {
    // UIImage -> cv::Mat変換
    frame = [self cvMatFromUIImage:image];
    
    // 背景差分法
    bgs->operator()(frame, curr, 0.8);
    
    // ノイズ除去
    Mat gaussian;
    GaussianBlur(curr, gaussian, Size2f(9, 9), 5);
    
    // 2値化
    Mat bin;
    threshold(gaussian, bin, 200, 255, cv::THRESH_BINARY);

    cv::Point currCenter;
    if (mode == 0) {
        // 輪郭検出
        std::vector<std::vector<cv::Point> > contours;
        std::vector<cv::Vec4i> hierarchy;
        cv::findContours(bin.clone(), contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
        std::vector<cv::Point> points;
        for (int i = 0; i < contours.size(); i++) {
            std::vector<cv::Point> contour = contours.at(i);
            points.push_back(contour.at(0));
        }
        
        if (points.size() > 10) {
            cv::Rect brect = cv::boundingRect(cv::Mat(points).reshape(2));
            cv::rectangle(frame, brect.tl(), brect.br(), cv::Scalar(0, 255, 0), 5, CV_AA);
            currCenter.x = brect.tl().x + (brect.br().x - brect.tl().x) / 2;
            currCenter.y = brect.tl().y + (brect.br().y - brect.tl().y) / 2;
        }
        
        if (abs(currCenter.x - prevCenter.x) > 100 && prevCenter.x != 0 && currCenter.x != 0) {
            double dx = currCenter.x - prevCenter.x;
            double dy = currCenter.y - prevCenter.y;
            double angle = atan2(dy, dx) * 180 / M_PI;
            prevCenter = cv::Point(0, 0);
            NSLog(@"x=%d, y=%d", currCenter.x, currCenter.y);
            NSLog(@"angle=%f", angle);
            
            if (angle > -90.0 && angle < 90.0) {
                gestureType = GestureType::LEFT;
            } else if ((angle > 90.0 && angle < 180.0) || (angle > -180.0 && angle < -90.0)) {
                gestureType = GestureType::RIGHT;
            }
        }
        
        // 初期座標更新
        if (prevCenter.x == 0 && currCenter.x != 0) {
            prevCenter = currCenter;
            delta = 0;
        }
        
        // 一定時間経過後リセット
        if (++delta > 20.0) {
            prevCenter = cv::Point(0, 0);
            delta = 0;
        }
    } else if (mode == 1) {
        // 重心計算
        IplImage binImg = bin;
        CvMoments moment;
        cvMoments(&binImg, &moment);
        double m00 = cvGetSpatialMoment(&moment, 0,0);
        currCenter.x = cvGetSpatialMoment(&moment, 1,0) / m00;
        currCenter.y = cvGetSpatialMoment(&moment, 0,1) / m00;
        if (currCenter.x != 0) {
            cv::circle(frame, currCenter, 50, cv::Scalar(255, 0, 0), 3, 8, 0);
        }
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        
        if (currCenter.x != 0 && gestureEnabled) {
            if (currCenter.x > screenSize.width / 2) {
                gestureType = GestureType::RIGHT;
            } else {
                gestureType = GestureType::LEFT;
            }
            gestureEnabled = false;
        }
        
        // 移動物体が検出されなくなったらリセット
        if (currCenter.x == 0) {
            gestureEnabled = true;
        }
    }
    
    
    // cv::Mat -> UIImage変換
    UIImage *resultImage = MatToUIImage(frame);
    
    return resultImage;
}

- (GestureType)getGestureType
{
    return gestureType;
}


- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    //    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end