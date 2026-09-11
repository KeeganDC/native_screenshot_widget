#import "NativeScreenshotWidgetPlugin.h"
#import "NativeScreenshotCaptureTarget.h"

@protocol NativeScreenshotLegacyWindowProviding <NSObject>

@optional
- (nullable UIWindow *)window;

@end

@interface NativeScreenshotWidgetPlugin ()

- (nullable UIWindow *)captureWindow;
- (void)takeScreenshotOnMainThreadWithCompletion:
    (nonnull void (^)(FlutterStandardTypedData *_Nullable, FlutterError *_Nullable))completion;
- (void)completeWithTakeScreenshotErrorDetails:(nullable NSString *)details
                                    completion:
    (nonnull void (^)(FlutterStandardTypedData *_Nullable, FlutterError *_Nullable))completion;

@end

@implementation NativeScreenshotWidgetPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    NativeScreenshotWidgetPlugin* instance = [[NativeScreenshotWidgetPlugin alloc] init];
    ScreenshotHostApiSetup(registrar.messenger, instance);
}


- (void)takeScreenshotWithCompletion:(nonnull void (^)(FlutterStandardTypedData * _Nullable, FlutterError * _Nullable))completion {
    if ([NSThread isMainThread]) {
        [self takeScreenshotOnMainThreadWithCompletion:completion];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self takeScreenshotOnMainThreadWithCompletion:completion];
    });
}

- (nullable UIWindow *)captureWindow {
    UIApplication *application = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        NSMutableArray<id<NativeScreenshotWindowScene>> *windowScenes =
            [NSMutableArray array];
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }

            id<NativeScreenshotWindowScene> windowScene =
                (id<NativeScreenshotWindowScene>)(UIWindowScene *)scene;
            [windowScenes addObject:windowScene];
        }
        return [NativeScreenshotCaptureTarget windowForForegroundActiveScenes:windowScenes];
    }

    id<NativeScreenshotLegacyWindowProviding> delegate =
        (id<NativeScreenshotLegacyWindowProviding>)application.delegate;
    UIWindow *delegateWindow = nil;
    if ([delegate respondsToSelector:@selector(window)]) {
        delegateWindow = [delegate window];
    }
    return [NativeScreenshotCaptureTarget legacyWindowFromDelegateWindow:delegateWindow];
}

- (void)takeScreenshotOnMainThreadWithCompletion:
    (nonnull void (^)(FlutterStandardTypedData *_Nullable, FlutterError *_Nullable))completion {
    UIWindow *window = [self captureWindow];
    UIView *view = [NativeScreenshotCaptureTarget captureViewForWindow:window];
    if (view == nil) {
        completion(nil, nil);
        return;
    }

    FlutterStandardTypedData *data = nil;
    NSString *failureDetails = nil;
    BOOL screenshotUnavailable = NO;
    @try {
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.opaque = view.opaque;
        UIScreen *screen = window.screen ?: UIScreen.mainScreen;
        if (screen.scale > 0.0) {
            format.scale = screen.scale;
        }

        UIGraphicsImageRenderer *renderer =
            [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size format:format];
        __block BOOL didDrawHierarchy = NO;
        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
            (void)rendererContext;
            didDrawHierarchy =
                [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
        }];
        if (!didDrawHierarchy) {
            screenshotUnavailable = YES;
        } else if (image == nil) {
            failureDetails = @"Unable to render screenshot.";
        } else {
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
            if (imageData == nil) {
                failureDetails = @"Unable to encode screenshot.";
            } else {
                data = [FlutterStandardTypedData typedDataWithBytes:imageData];
                if (data == nil) {
                    failureDetails = @"Unable to return screenshot data.";
                }
            }
        }
    } @catch (NSException *exception) {
        failureDetails = exception.description ?: @"Unable to render screenshot.";
    }

    if (screenshotUnavailable) {
        completion(nil, nil);
        return;
    }
    if (failureDetails != nil) {
        [self completeWithTakeScreenshotErrorDetails:failureDetails completion:completion];
        return;
    }

    completion(data, nil);
}

- (void)completeWithTakeScreenshotErrorDetails:(nullable NSString *)details
                                    completion:
    (nonnull void (^)(FlutterStandardTypedData *_Nullable, FlutterError *_Nullable))completion {
    FlutterError *error = [FlutterError errorWithCode:@"TakeScreenshotError"
                                               message:@"Failed takeScreenshot."
                                               details:details];
    completion(nil, error);
}

@end
