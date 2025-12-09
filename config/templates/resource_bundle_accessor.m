#import <Foundation/Foundation.h>

@interface BundleFinder_{{MODULE_NAME}} : NSObject
@end

@implementation BundleFinder_{{MODULE_NAME}}
@end

NSBundle* {{MODULE_NAME}}_SWIFTPM_MODULE_BUNDLE() {
  NSString *bundleName = @"{{PACKAGE_NAME}}_{{TARGET_NAME}}";
  NSArray<NSURL *> *candidates = @[
    NSBundle.mainBundle.resourceURL,
    [NSBundle bundleForClass:[BundleFinder_{{MODULE_NAME}} class]].resourceURL,
    NSBundle.mainBundle.bundleURL,
    [NSBundle.mainBundle.bundleURL URLByAppendingPathComponent:@"Frameworks/{{TARGET_NAME}}.framework"]
  ];

  for (NSURL *candidate in candidates) {
    NSURL *bundlePath = [candidate URLByAppendingPathComponent:[bundleName stringByAppendingString:@".bundle"]];
    NSBundle *bundle = [NSBundle bundleWithURL:bundlePath];
    if (bundle) {
      return bundle;
    }
  }
  [NSException raise:NSInternalInconsistencyException format:@"Unable to find bundle named %@", bundleName];
  return nil;
}
