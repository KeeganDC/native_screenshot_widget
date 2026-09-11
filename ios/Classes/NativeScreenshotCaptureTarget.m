#import "NativeScreenshotCaptureTarget.h"

@interface NativeScreenshotCaptureTarget ()

+ (nullable UIWindow *)keyWindowFromWindows:(NSArray<UIWindow *> *)windows;
+ (nullable UIWindow *)visibleNormalWindowFromWindows:(NSArray<UIWindow *> *)windows;
+ (BOOL)isVisibleWindowWithNonEmptyBounds:(nullable UIWindow *)window;

@end

@implementation NativeScreenshotCaptureTarget

+ (nullable UIWindow *)windowForForegroundActiveScenes:
    (NSArray<id<NativeScreenshotWindowScene>> *)scenes {
  for (id<NativeScreenshotWindowScene> scene in scenes) {
    if (scene.activationState != UISceneActivationStateForegroundActive) {
      continue;
    }

    UIWindow *keyWindow = [self keyWindowFromWindows:scene.windows];
    if (keyWindow != nil) {
      return keyWindow;
    }
  }

  for (id<NativeScreenshotWindowScene> scene in scenes) {
    if (scene.activationState != UISceneActivationStateForegroundActive) {
      continue;
    }

    UIWindow *fallbackWindow = [self visibleNormalWindowFromWindows:scene.windows];
    if (fallbackWindow != nil) {
      return fallbackWindow;
    }
  }

  return nil;
}

+ (nullable UIWindow *)legacyWindowFromDelegateWindow:(nullable UIWindow *)delegateWindow {
  return [self isVisibleWindowWithNonEmptyBounds:delegateWindow] ? delegateWindow : nil;
}

+ (nullable UIView *)captureViewForWindow:(nullable UIWindow *)window {
  if (window == nil) {
    return nil;
  }

  UIViewController *rootViewController = window.rootViewController;
  if (rootViewController == nil || !rootViewController.isViewLoaded) {
    return nil;
  }

  UIView *view = rootViewController.view;
  if (view == nil || view.window == nil) {
    return nil;
  }

  CGRect bounds = view.bounds;
  if (CGRectGetWidth(bounds) <= 0.0 || CGRectGetHeight(bounds) <= 0.0) {
    return nil;
  }

  return view;
}

+ (nullable UIWindow *)keyWindowFromWindows:(NSArray<UIWindow *> *)windows {
  for (UIWindow *window in windows) {
    if (window.isKeyWindow && [self isVisibleWindowWithNonEmptyBounds:window]) {
      return window;
    }
  }

  return nil;
}

+ (nullable UIWindow *)visibleNormalWindowFromWindows:(NSArray<UIWindow *> *)windows {
  for (UIWindow *window in windows) {
    if (window.windowLevel == UIWindowLevelNormal &&
        [self isVisibleWindowWithNonEmptyBounds:window]) {
      return window;
    }
  }

  return nil;
}

+ (BOOL)isVisibleWindowWithNonEmptyBounds:(nullable UIWindow *)window {
  if (window == nil || window.hidden || window.alpha <= 0.0) {
    return NO;
  }

  CGRect bounds = window.bounds;
  return CGRectGetWidth(bounds) > 0.0 && CGRectGetHeight(bounds) > 0.0;
}

@end
