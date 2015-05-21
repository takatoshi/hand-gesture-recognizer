//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum GestureType {LEFT, RIGHT};

@interface Detector: NSObject

- (id)init;
- (UIImage *)recognizeGesture:(UIImage *)image mode:(NSInteger)mode;
- (int)getGestureType;

@end