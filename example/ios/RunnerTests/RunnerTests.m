#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <native_screenshot_widget/NativeScreenshotCaptureTarget.h>

@interface NativeScreenshotCaptureTargetTestWindow : UIWindow

@property(nonatomic, assign) BOOL testKeyWindow;

@end

@implementation NativeScreenshotCaptureTargetTestWindow

- (BOOL)isKeyWindow {
  return self.testKeyWindow;
}

@end

API_AVAILABLE(ios(13.0))
@interface NativeScreenshotCaptureTargetTestScene : NSObject<NativeScreenshotWindowScene>

@property(nonatomic, assign) UISceneActivationState activationState;
@property(nonatomic, copy) NSArray<UIWindow *> *windows;

@end

@implementation NativeScreenshotCaptureTargetTestScene

@end

@interface RunnerTests : XCTestCase

@end

@implementation RunnerTests

- (NativeScreenshotCaptureTargetTestWindow *)visibleWindow {
  NativeScreenshotCaptureTargetTestWindow *window =
      [[NativeScreenshotCaptureTargetTestWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  window.hidden = NO;
  window.alpha = 1.0;
  window.windowLevel = UIWindowLevelNormal;
  return window;
}

- (NativeScreenshotCaptureTargetTestScene *)foregroundActiveSceneWithWindows:
    (NSArray<UIWindow *> *)windows API_AVAILABLE(ios(13.0)) {
  NativeScreenshotCaptureTargetTestScene *scene =
      [[NativeScreenshotCaptureTargetTestScene alloc] init];
  scene.activationState = UISceneActivationStateForegroundActive;
  scene.windows = windows;
  return scene;
}

- (void)testForegroundActiveScenePrefersKeyWindow {
  if (@available(iOS 13.0, *)) {
    NativeScreenshotCaptureTargetTestWindow *fallbackWindow = [self visibleWindow];
    NativeScreenshotCaptureTargetTestWindow *keyWindow = [self visibleWindow];
    keyWindow.testKeyWindow = YES;
    NativeScreenshotCaptureTargetTestScene *scene =
        [self foregroundActiveSceneWithWindows:@[
          fallbackWindow,
          keyWindow,
        ]];

    UIWindow *selectedWindow = [NativeScreenshotCaptureTarget
        windowForForegroundActiveScenes:@[scene]];

    XCTAssertEqual(selectedWindow, keyWindow);
  }
}

- (void)testForegroundActiveSceneUsesVisibleNormalWindowWhenNoKeyWindow {
  if (@available(iOS 13.0, *)) {
    NativeScreenshotCaptureTargetTestWindow *hiddenWindow = [self visibleWindow];
    hiddenWindow.hidden = YES;
    hiddenWindow.testKeyWindow = YES;
    NativeScreenshotCaptureTargetTestWindow *fallbackWindow = [self visibleWindow];
    NativeScreenshotCaptureTargetTestScene *scene =
        [self foregroundActiveSceneWithWindows:@[
          hiddenWindow,
          fallbackWindow,
        ]];

    UIWindow *selectedWindow = [NativeScreenshotCaptureTarget
        windowForForegroundActiveScenes:@[scene]];

    XCTAssertEqual(selectedWindow, fallbackWindow);
  }
}

- (void)testNoForegroundActiveSceneReturnsNil {
  if (@available(iOS 13.0, *)) {
    NativeScreenshotCaptureTargetTestScene *backgroundScene =
        [self foregroundActiveSceneWithWindows:@[[self visibleWindow]]];
    backgroundScene.activationState = UISceneActivationStateBackground;

    UIWindow *selectedWindow =
        [NativeScreenshotCaptureTarget windowForForegroundActiveScenes:@[backgroundScene]];

    XCTAssertNil(selectedWindow);
  }
}

- (void)testForegroundActiveSceneWithoutUsableWindowReturnsNil {
  if (@available(iOS 13.0, *)) {
    NativeScreenshotCaptureTargetTestWindow *emptyWindow =
        [[NativeScreenshotCaptureTargetTestWindow alloc] initWithFrame:CGRectZero];
    emptyWindow.hidden = NO;
    NativeScreenshotCaptureTargetTestScene *scene =
        [self foregroundActiveSceneWithWindows:@[emptyWindow]];

    UIWindow *selectedWindow = [NativeScreenshotCaptureTarget
        windowForForegroundActiveScenes:@[scene]];

    XCTAssertNil(selectedWindow);
  }
}

- (void)testZeroSizedAttachedRootViewIsUnavailableForCapture {
  NativeScreenshotCaptureTargetTestWindow *window = [self visibleWindow];
  UIViewController *rootViewController = [[UIViewController alloc] init];
  UIView *rootView = [[UIView alloc] initWithFrame:CGRectZero];
  rootViewController.view = rootView;
  window.rootViewController = rootViewController;
  [window addSubview:rootView];
  rootView.frame = CGRectZero;

  XCTAssertEqual(rootView.window, window);
  XCTAssertTrue(CGRectIsEmpty(rootView.bounds));
  XCTAssertNil([NativeScreenshotCaptureTarget captureViewForWindow:window]);
}

- (void)testLegacyPreIOS13FallbackUsesVisibleWindow {
  NativeScreenshotCaptureTargetTestWindow *delegateWindow = [self visibleWindow];

  XCTAssertEqual(
      [NativeScreenshotCaptureTarget legacyWindowFromDelegateWindow:delegateWindow], delegateWindow);
  delegateWindow.hidden = YES;
  XCTAssertNil([NativeScreenshotCaptureTarget legacyWindowFromDelegateWindow:delegateWindow]);
}

@end
