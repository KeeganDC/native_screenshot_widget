#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NativeScreenshotWindowScene <NSObject>

@property(nonatomic, readonly) UISceneActivationState activationState API_AVAILABLE(ios(13.0));
@property(nonatomic, copy, readonly) NSArray<UIWindow *> *windows API_AVAILABLE(ios(13.0));

@end

@interface NativeScreenshotCaptureTarget : NSObject

+ (nullable UIWindow *)windowForForegroundActiveScenes:
    (NSArray<id<NativeScreenshotWindowScene>> *)scenes API_AVAILABLE(ios(13.0));

+ (nullable UIWindow *)legacyWindowFromDelegateWindow:(nullable UIWindow *)delegateWindow;

+ (nullable UIView *)captureViewForWindow:(nullable UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
