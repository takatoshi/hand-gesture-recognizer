//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GestureType) {
    GestureTypeNone,
    GestureTypeLeft,
    GestureTypeRight
};

@interface Detector: NSObject

- (id)init;
- (UIImage *)detectGesture:(UIImage *)image mode:(NSInteger)mode;
- (GestureType)getGestureType;

@end