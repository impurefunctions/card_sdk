#import "CardSdkPlugin.h"
#if __has_include(<card_sdk/card_sdk-Swift.h>)
#import <card_sdk/card_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "card_sdk-Swift.h"
#endif

@implementation CardSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCardSdkPlugin registerWithRegistrar:registrar];
}
@end
